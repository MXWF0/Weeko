package io.github.mxwf.weeko.feature.coursedetail

import io.github.mxwf.weeko.designsystem.WeekoCoursePalette
import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.SessionWeek
import io.github.mxwf.weeko.model.TimeSlot
import org.junit.Assert.assertEquals
import org.junit.Test

class CourseDetailMapperTest {
    @Test
    fun mapsDomainRecordToPresentationState() {
        val record = CourseDetailRecord(
            course = Course(
                id = "course-1",
                scheduleId = "schedule-1",
                name = "数据结构",
                colorSeed = 1,
                note = "带作业本",
            ),
            sessions = listOf(
                CourseSessionRecord(
                    session = CourseSession(
                        id = "session-1",
                        courseId = "course-1",
                        dayOfWeek = 1,
                        startPeriod = 1,
                        endPeriod = 2,
                        room = "A101",
                        teacher = "李老师",
                    ),
                    weeks = listOf(
                        SessionWeek("session-1", 1),
                        SessionWeek("session-1", 2),
                        SessionWeek("session-1", 4),
                    ),
                ),
                CourseSessionRecord(
                    session = CourseSession(
                        id = "session-2",
                        courseId = "course-1",
                        dayOfWeek = 3,
                        startPeriod = 3,
                        endPeriod = 3,
                        room = "B202",
                        teacher = "王老师",
                        startMinute = 600,
                        endMinute = 650,
                    ),
                    weeks = listOf(SessionWeek("session-2", 6)),
                ),
            ),
            timeSlots = listOf(
                TimeSlot("profile-1", 1, 480, 530),
                TimeSlot("profile-1", 2, 540, 590),
            ),
        )

        val state = record.toUiState()

        assertEquals("数据结构", state.courseName)
        assertEquals(WeekoCoursePalette.Sage, state.courseColor)
        assertEquals("A101", state.room)
        assertEquals("李老师", state.teacher)
        assertEquals("星期一、星期三", state.dayOfWeek)
        assertEquals("08:00–09:50、10:00–10:50", state.timeRange)
        assertEquals("第 1–2 节、第 3–3 节", state.periods)
        assertEquals("第 1–2、4、6 周", state.weeks)
        assertEquals("带作业本", state.note)
    }
}
