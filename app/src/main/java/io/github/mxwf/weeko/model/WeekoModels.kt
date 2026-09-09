package io.github.mxwf.weeko.model

import java.time.DayOfWeek
import java.time.LocalDate

data class Semester(
    val id: String,
    val name: String,
    val startDate: LocalDate,
    val weekCount: Int,
    val weekStartsOn: DayOfWeek = DayOfWeek.MONDAY,
)

data class Schedule(
    val id: String,
    val semesterId: String,
    val name: String,
    val isArchived: Boolean = false,
)

data class Course(
    val id: String,
    val scheduleId: String,
    val name: String,
    val colorSeed: Long,
    val note: String = "",
    val credit: Double? = null,
    val courseCode: String? = null,
)

data class CourseSession(
    val id: String,
    val courseId: String,
    val dayOfWeek: Int,
    val startPeriod: Int,
    val endPeriod: Int,
    val room: String = "",
    val teacher: String = "",
    val startMinute: Int? = null,
    val endMinute: Int? = null,
)

data class SessionWeek(
    val sessionId: String,
    val weekIndex: Int,
)

data class TimeProfile(
    val id: String,
    val scheduleId: String,
    val name: String,
)

data class TimeSlot(
    val timeProfileId: String,
    val periodIndex: Int,
    val startMinute: Int,
    val endMinute: Int,
)

data class CourseSessionRecord(
    val session: CourseSession,
    val weeks: List<SessionWeek>,
)

data class CourseDetailRecord(
    val course: Course,
    val sessions: List<CourseSessionRecord>,
    val timeSlots: List<TimeSlot>,
    val weekCount: Int = 20,
)

data class CourseAggregate(
    val course: Course,
    val sessions: List<CourseSessionRecord>,
)

data class ScheduleAggregate(
    val semester: Semester,
    val schedule: Schedule,
    val timeProfile: TimeProfile,
    val timeSlots: List<TimeSlot>,
    val courses: List<CourseAggregate>,
)
