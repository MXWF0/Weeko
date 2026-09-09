package io.github.mxwf.weeko.feature.editor

import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.SessionWeek
import io.github.mxwf.weeko.model.TimeSlot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CourseEditorUiStateTest {
    @Test
    fun mapsAllSessionFieldsAndConvertsBackToDomain() {
        val record = CourseDetailRecord(
            course = Course(
                id = "course-1",
                scheduleId = "schedule-1",
                name = "离散数学",
                colorSeed = 3,
                note = "带作业",
                credit = 2.5,
                courseCode = "MATH-101",
            ),
            sessions = listOf(
                CourseSessionRecord(
                    session = CourseSession(
                        id = "session-1",
                        courseId = "course-1",
                        dayOfWeek = 2,
                        startPeriod = 3,
                        endPeriod = 4,
                        room = "B204",
                        teacher = "张老师",
                        startMinute = 600,
                        endMinute = 690,
                    ),
                    weeks = listOf(
                        SessionWeek("session-1", 1),
                        SessionWeek("session-1", 3),
                    ),
                ),
            ),
            timeSlots = listOf(TimeSlot("profile-1", 3, 600, 645)),
            weekCount = 12,
        )

        val form = record.toEditorForm()
        assertEquals("离散数学", form.name)
        assertEquals("2.5", form.credit)
        assertEquals(12, form.weekCount)
        assertEquals("10:00", form.sessions.single().customStartTime)
        assertEquals(listOf(1, 3), form.sessions.single().selectedWeeks)

        val saveData = form.toSaveData()
        assertEquals(record.course, saveData.course)
        assertEquals(record.sessions.single().session, saveData.sessions.single().session)
        assertEquals(record.sessions.single().weeks, saveData.sessions.single().weeks)
    }

    @Test
    fun invalidFormReportsAnErrorWithoutBuildingSaveData() {
        val form = CourseEditorForm(
            courseId = "course-1",
            scheduleId = "schedule-1",
            name = " ",
            courseCode = "",
            credit = "not-a-number",
            colorSeed = 0,
            note = "",
            weekCount = 16,
            sessions = emptyList(),
        )

        assertEquals("课程名称不能为空", form.validationError())
        assertNull(CourseEditorForm(
            courseId = "course-1",
            scheduleId = "schedule-1",
            name = "课程",
            courseCode = "",
            credit = "",
            colorSeed = 0,
            note = "",
            weekCount = 16,
            sessions = listOf(
                CourseEditorSessionForm(
                    id = "session-1",
                    dayOfWeek = 1,
                    startPeriod = "1",
                    endPeriod = "2",
                    room = "",
                    teacher = "",
                    selectedWeeks = listOf(1, 2),
                    customStartTime = "",
                    customEndTime = "",
                ),
            ),
        ).validationError())
    }
}
