package io.github.mxwf.weeko.data

import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import io.github.mxwf.weeko.database.WeekoDatabase
import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseAggregate
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.Schedule
import io.github.mxwf.weeko.model.ScheduleAggregate
import io.github.mxwf.weeko.model.Semester
import io.github.mxwf.weeko.model.SessionWeek
import io.github.mxwf.weeko.model.TimeProfile
import io.github.mxwf.weeko.model.TimeSlot
import java.time.DayOfWeek
import java.time.LocalDate
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class RoomWeekoRepositoryTest {
    private lateinit var database: WeekoDatabase

    @Before
    fun setUp() {
        database = Room.inMemoryDatabaseBuilder(
            ApplicationProvider.getApplicationContext(),
            WeekoDatabase::class.java,
        ).build()
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun scheduleRoundTripAndCourseCascadeDelete() = runBlocking {
        val repository = RoomWeekoRepository(database)
        repository.insertSchedule(sampleAggregate())

        val detail = repository.observeCourseDetail("course-1").first { it != null }
        requireNotNull(detail)
        assertEquals("数据库原理", detail.course.name)
        assertEquals(listOf(1, 3), detail.sessions.single().weeks.map { it.weekIndex })
        assertEquals(1, detail.timeSlots.size)
        assertTrue(repository.deleteCourse("course-1"))

        assertEquals(null, repository.observeCourseDetail("course-1").first())
    }

    @Test
    fun saveCourseReplacesSessionsAndPreservesRoomTransactionBoundary() = runBlocking {
        val repository = RoomWeekoRepository(database)
        repository.insertSchedule(sampleAggregate())

        val updated = Course(
            id = "course-1",
            scheduleId = "schedule-1",
            name = "更新后的数据库原理",
            colorSeed = 4,
            note = "新备注",
        )
        val sessions = listOf(
            CourseSessionRecord(
                session = CourseSession(
                    id = "session-2",
                    courseId = "course-1",
                    dayOfWeek = 5,
                    startPeriod = 2,
                    endPeriod = 3,
                    room = "C302",
                    teacher = "新老师",
                    startMinute = 600,
                    endMinute = 710,
                ),
                weeks = listOf(
                    SessionWeek("session-2", 2),
                    SessionWeek("session-2", 4),
                ),
            ),
        )

        assertTrue(repository.saveCourse(updated, sessions))

        val detail = repository.observeCourseDetail("course-1").first {
            it?.course?.name == "更新后的数据库原理"
        }
        requireNotNull(detail)
        assertEquals("新备注", detail.course.note)
        assertEquals("C302", detail.sessions.single().session.room)
        assertEquals(listOf(2, 4), detail.sessions.single().weeks.map { it.weekIndex })
    }

    private fun sampleAggregate() = ScheduleAggregate(
        semester = Semester(
            id = "semester-1",
            name = "2026 春季学期",
            startDate = LocalDate.of(2026, 2, 23),
            weekCount = 16,
            weekStartsOn = DayOfWeek.MONDAY,
        ),
        schedule = Schedule("schedule-1", "semester-1", "主课表"),
        timeProfile = TimeProfile("profile-1", "schedule-1", "默认作息"),
        timeSlots = listOf(TimeSlot("profile-1", 1, 480, 530)),
        courses = listOf(
            CourseAggregate(
                course = Course(
                    id = "course-1",
                    scheduleId = "schedule-1",
                    name = "数据库原理",
                    colorSeed = 2,
                ),
                sessions = listOf(
                    CourseSessionRecord(
                        session = CourseSession(
                            id = "session-1",
                            courseId = "course-1",
                            dayOfWeek = 2,
                            startPeriod = 1,
                            endPeriod = 1,
                            room = "B101",
                            teacher = "赵老师",
                        ),
                        weeks = listOf(
                            SessionWeek("session-1", 1),
                            SessionWeek("session-1", 3),
                        ),
                    ),
                ),
            ),
        ),
    )
}
