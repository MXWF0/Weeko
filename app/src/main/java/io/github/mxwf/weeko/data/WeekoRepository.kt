package io.github.mxwf.weeko.data

import androidx.room.withTransaction
import io.github.mxwf.weeko.database.CourseEntity
import io.github.mxwf.weeko.database.CourseSessionEntity
import io.github.mxwf.weeko.database.CourseWithSessionsEntity
import io.github.mxwf.weeko.database.ScheduleEntity
import io.github.mxwf.weeko.database.SemesterEntity
import io.github.mxwf.weeko.database.SessionWeekEntity
import io.github.mxwf.weeko.database.TimeProfileEntity
import io.github.mxwf.weeko.database.TimeSlotEntity
import io.github.mxwf.weeko.database.WeekoDatabase
import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.ScheduleAggregate
import io.github.mxwf.weeko.model.SessionWeek
import io.github.mxwf.weeko.model.TimeSlot
import java.time.DayOfWeek
import java.time.LocalDate
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.ExperimentalCoroutinesApi

interface CourseDetailRepository {
    fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?>

    suspend fun deleteCourse(courseId: String): Boolean
}

interface CourseEditorRepository {
    fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?>

    suspend fun saveCourse(
        course: Course,
        sessions: List<CourseSessionRecord>,
    ): Boolean
}

@OptIn(ExperimentalCoroutinesApi::class)
class RoomWeekoRepository(
    private val database: WeekoDatabase,
) : CourseDetailRepository, CourseEditorRepository {
    override fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?> =
        database.courseDao().observeWithSessions(courseId).flatMapLatest { courseWithSessions ->
            if (courseWithSessions == null) {
                flowOf(null)
            } else {
                database.scheduleDao()
                    .observeWithSemester(courseWithSessions.course.scheduleId)
                    .flatMapLatest { schedule ->
                        val weekCount = requireNotNull(schedule).semester.weekCount
                        database.timeProfileDao()
                            .observeForSchedule(courseWithSessions.course.scheduleId)
                            .flatMapLatest { profile ->
                                if (profile == null) {
                                    flowOf(courseWithSessions.toDomain(emptyList(), weekCount))
                                } else {
                                    database.timeSlotDao().observeForProfile(profile.id).map { slots ->
                                        courseWithSessions.toDomain(
                                            slots.map(TimeSlotEntity::toDomain),
                                            weekCount,
                                        )
                                    }
                                }
                            }
                    }
            }
        }

    override suspend fun deleteCourse(courseId: String): Boolean =
        database.courseDao().deleteById(courseId) > 0

    override suspend fun saveCourse(
        course: Course,
        sessions: List<CourseSessionRecord>,
    ): Boolean {
        var updated = false
        database.withTransaction {
            if (database.courseDao().update(course.toEntity()) > 0) {
                database.courseSessionDao().deleteForCourse(course.id)
                database.courseSessionDao().insertAll(
                    sessions.map { it.session.toEntity() },
                )
                database.sessionWeekDao().insertAll(
                    sessions.flatMap { it.weeks.map(SessionWeek::toEntity) },
                )
                updated = true
            }
        }
        return updated
    }

    suspend fun insertSchedule(aggregate: ScheduleAggregate) {
        database.withTransaction {
            database.semesterDao().insert(aggregate.semester.toEntity())
            database.scheduleDao().insert(aggregate.schedule.toEntity())
            database.timeProfileDao().insert(aggregate.timeProfile.toEntity())
            database.timeSlotDao().insertAll(aggregate.timeSlots.map(TimeSlot::toEntity))

            database.courseDao().insertAll(aggregate.courses.map { it.course.toEntity() })
            val sessions = aggregate.courses.flatMap { course ->
                course.sessions.map { it.session.toEntity() }
            }
            database.courseSessionDao().insertAll(sessions)
            database.sessionWeekDao().insertAll(
                aggregate.courses.flatMap { course ->
                    course.sessions.flatMap { it.weeks.map(SessionWeek::toEntity) }
                },
            )
        }
    }
}

private fun CourseWithSessionsEntity.toDomain(
    timeSlots: List<TimeSlot>,
    weekCount: Int,
): CourseDetailRecord =
    CourseDetailRecord(
        course = course.toDomain(),
        sessions = sessions.map { sessionWithWeeks ->
            CourseSessionRecord(
                session = sessionWithWeeks.session.toDomain(),
                weeks = sessionWithWeeks.weeks.map { it.toDomain() },
            )
        },
        timeSlots = timeSlots,
        weekCount = weekCount,
    )

private fun SemesterEntity.toDomain() =
    io.github.mxwf.weeko.model.Semester(
        id = id,
        name = name,
        startDate = LocalDate.parse(startDate),
        weekCount = weekCount,
        weekStartsOn = DayOfWeek.of(weekStartsOn),
    )

private fun io.github.mxwf.weeko.model.Semester.toEntity() =
    SemesterEntity(id, name, startDate.toString(), weekCount, weekStartsOn.value)

private fun io.github.mxwf.weeko.model.Schedule.toEntity() =
    ScheduleEntity(id, semesterId, name, isArchived)

private fun io.github.mxwf.weeko.model.TimeProfile.toEntity() =
    TimeProfileEntity(id, scheduleId, name)

private fun Course.toEntity() =
    CourseEntity(id, scheduleId, name, colorSeed, note, credit, courseCode)

private fun CourseEntity.toDomain() =
    Course(id, scheduleId, name, colorSeed, note, credit, courseCode)

private fun CourseSession.toEntity() =
    CourseSessionEntity(
        id,
        courseId,
        dayOfWeek,
        startPeriod,
        endPeriod,
        room,
        teacher,
        startMinute,
        endMinute,
    )

private fun CourseSessionEntity.toDomain() =
    CourseSession(
        id,
        courseId,
        dayOfWeek,
        startPeriod,
        endPeriod,
        room,
        teacher,
        startMinute,
        endMinute,
    )

private fun SessionWeek.toEntity() = SessionWeekEntity(sessionId, weekIndex)

private fun SessionWeekEntity.toDomain() = SessionWeek(sessionId, weekIndex)

private fun TimeSlot.toEntity() =
    TimeSlotEntity(timeProfileId, periodIndex, startMinute, endMinute)

private fun TimeSlotEntity.toDomain() =
    TimeSlot(timeProfileId, periodIndex, startMinute, endMinute)
