package io.github.mxwf.weeko.database

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import androidx.room.Relation

@Entity(tableName = "semesters")
data class SemesterEntity(
    @PrimaryKey val id: String,
    val name: String,
    @ColumnInfo(name = "start_date") val startDate: String,
    @ColumnInfo(name = "week_count") val weekCount: Int,
    @ColumnInfo(name = "week_starts_on") val weekStartsOn: Int,
)

@Entity(
    tableName = "schedules",
    foreignKeys = [
        ForeignKey(
            entity = SemesterEntity::class,
            parentColumns = ["id"],
            childColumns = ["semester_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["semester_id"])],
)
data class ScheduleEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "semester_id") val semesterId: String,
    val name: String,
    @ColumnInfo(name = "is_archived") val isArchived: Boolean,
)

@Entity(
    tableName = "courses",
    foreignKeys = [
        ForeignKey(
            entity = ScheduleEntity::class,
            parentColumns = ["id"],
            childColumns = ["schedule_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["schedule_id"])],
)
data class CourseEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "schedule_id") val scheduleId: String,
    val name: String,
    @ColumnInfo(name = "color_seed") val colorSeed: Long,
    val note: String,
    val credit: Double?,
    @ColumnInfo(name = "course_code") val courseCode: String?,
)

@Entity(
    tableName = "course_sessions",
    foreignKeys = [
        ForeignKey(
            entity = CourseEntity::class,
            parentColumns = ["id"],
            childColumns = ["course_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index(value = ["course_id"]),
        Index(value = ["day_of_week", "start_period"]),
    ],
)
data class CourseSessionEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "course_id") val courseId: String,
    @ColumnInfo(name = "day_of_week") val dayOfWeek: Int,
    @ColumnInfo(name = "start_period") val startPeriod: Int,
    @ColumnInfo(name = "end_period") val endPeriod: Int,
    val room: String,
    val teacher: String,
    @ColumnInfo(name = "start_minute") val startMinute: Int?,
    @ColumnInfo(name = "end_minute") val endMinute: Int?,
)

@Entity(
    tableName = "session_weeks",
    primaryKeys = ["session_id", "week_index"],
    foreignKeys = [
        ForeignKey(
            entity = CourseSessionEntity::class,
            parentColumns = ["id"],
            childColumns = ["session_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["session_id"]), Index(value = ["week_index"])],
)
data class SessionWeekEntity(
    @ColumnInfo(name = "session_id") val sessionId: String,
    @ColumnInfo(name = "week_index") val weekIndex: Int,
)

@Entity(
    tableName = "time_profiles",
    foreignKeys = [
        ForeignKey(
            entity = ScheduleEntity::class,
            parentColumns = ["id"],
            childColumns = ["schedule_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["schedule_id"], unique = true)],
)
data class TimeProfileEntity(
    @PrimaryKey val id: String,
    @ColumnInfo(name = "schedule_id") val scheduleId: String,
    val name: String,
)

@Entity(
    tableName = "time_slots",
    primaryKeys = ["time_profile_id", "period_index"],
    foreignKeys = [
        ForeignKey(
            entity = TimeProfileEntity::class,
            parentColumns = ["id"],
            childColumns = ["time_profile_id"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [Index(value = ["time_profile_id"])],
)
data class TimeSlotEntity(
    @ColumnInfo(name = "time_profile_id") val timeProfileId: String,
    @ColumnInfo(name = "period_index") val periodIndex: Int,
    @ColumnInfo(name = "start_minute") val startMinute: Int,
    @ColumnInfo(name = "end_minute") val endMinute: Int,
)

data class CourseWithSessionsEntity(
    @Embedded val course: CourseEntity,
    @Relation(
        entity = CourseSessionEntity::class,
        parentColumn = "id",
        entityColumn = "course_id",
    )
    val sessions: List<CourseSessionWithWeeksEntity>,
)

data class ScheduleWithSemesterEntity(
    @Embedded val schedule: ScheduleEntity,
    @Relation(
        parentColumn = "semester_id",
        entityColumn = "id",
    )
    val semester: SemesterEntity,
)

data class CourseSessionWithWeeksEntity(
    @Embedded val session: CourseSessionEntity,
    @Relation(
        parentColumn = "id",
        entityColumn = "session_id",
    )
    val weeks: List<SessionWeekEntity>,
)
