package io.github.mxwf.weeko.feature.editor

import androidx.compose.runtime.Immutable
import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.SessionWeek
import java.util.Locale

@Immutable
sealed interface CourseEditorUiState {
    @Immutable
    data object Loading : CourseEditorUiState

    @Immutable
    data class Content(
        val form: CourseEditorForm,
        val isSaving: Boolean = false,
        val errorMessage: String? = null,
    ) : CourseEditorUiState

    @Immutable
    data object NotFound : CourseEditorUiState

    @Immutable
    data class Error(val message: String) : CourseEditorUiState
}

@Immutable
data class CourseEditorForm(
    val courseId: String,
    val scheduleId: String,
    val name: String,
    val courseCode: String,
    val credit: String,
    val colorSeed: Long,
    val note: String,
    val weekCount: Int,
    val sessions: List<CourseEditorSessionForm>,
)

@Immutable
data class CourseEditorSessionForm(
    val id: String,
    val dayOfWeek: Int,
    val startPeriod: String,
    val endPeriod: String,
    val room: String,
    val teacher: String,
    val selectedWeeks: List<Int>,
    val customStartTime: String,
    val customEndTime: String,
)

internal data class CourseEditorSaveData(
    val course: Course,
    val sessions: List<CourseSessionRecord>,
)

internal fun CourseDetailRecord.toEditorForm(): CourseEditorForm =
    CourseEditorForm(
        courseId = course.id,
        scheduleId = course.scheduleId,
        name = course.name,
        courseCode = course.courseCode.orEmpty(),
        credit = course.credit?.toString().orEmpty(),
        colorSeed = course.colorSeed,
        note = course.note,
        weekCount = weekCount.coerceAtLeast(1),
        sessions = sessions.map { it.toEditorForm() },
    )

private fun CourseSessionRecord.toEditorForm() =
    CourseEditorSessionForm(
        id = session.id,
        dayOfWeek = session.dayOfWeek,
        startPeriod = session.startPeriod.toString(),
        endPeriod = session.endPeriod.toString(),
        room = session.room,
        teacher = session.teacher,
        selectedWeeks = weeks.map(SessionWeek::weekIndex).distinct().sorted(),
        customStartTime = session.startMinute?.let(::formatMinute).orEmpty(),
        customEndTime = session.endMinute?.let(::formatMinute).orEmpty(),
    )

internal fun CourseEditorForm.validationError(): String? {
    if (name.isBlank()) return "课程名称不能为空"
    val creditValue = credit.trim().takeIf(String::isNotEmpty)?.toDoubleOrNull()
    if (credit.trim().isNotEmpty() && (creditValue == null || creditValue < 0.0)) {
        return "学分必须是非负数字"
    }
    if (sessions.isEmpty()) return "至少保留一个上课安排"
    sessions.forEachIndexed { index, session ->
        val number = index + 1
        if (session.dayOfWeek !in 1..7) return "第 $number 个安排的星期无效"
        val startPeriod = session.startPeriod.toIntOrNull()
        val endPeriod = session.endPeriod.toIntOrNull()
        if (startPeriod == null || startPeriod < 1) return "第 $number 个安排的起始节次无效"
        if (endPeriod == null || endPeriod < startPeriod) return "第 $number 个安排的结束节次无效"
        if (session.selectedWeeks.any { it !in 1..weekCount }) {
            return "第 $number 个安排包含超出学期的周次"
        }
        if (session.selectedWeeks.distinct().size != session.selectedWeeks.size) {
            return "第 $number 个安排的周次重复"
        }
        val hasStart = session.customStartTime.isNotBlank()
        val hasEnd = session.customEndTime.isNotBlank()
        if (hasStart != hasEnd) return "第 $number 个安排的自定义时间需要填写完整"
        if (hasStart) {
            val startMinute = parseMinute(session.customStartTime)
            val endMinute = parseMinute(session.customEndTime)
            if (startMinute == null || endMinute == null) {
                return "第 $number 个安排的自定义时间格式无效"
            }
            if (endMinute <= startMinute) return "第 $number 个安排的结束时间必须晚于开始时间"
        }
    }
    return null
}

internal fun CourseEditorForm.toSaveData(): CourseEditorSaveData {
    val creditValue = credit.trim().takeIf(String::isNotEmpty)?.toDouble()
    return CourseEditorSaveData(
        course = Course(
            id = courseId,
            scheduleId = scheduleId,
            name = name.trim(),
            colorSeed = colorSeed,
            note = note,
            credit = creditValue,
            courseCode = courseCode.trim().takeIf(String::isNotEmpty),
        ),
        sessions = sessions.map { session ->
            val startPeriod = session.startPeriod.toInt()
            val endPeriod = session.endPeriod.toInt()
            CourseSessionRecord(
                session = CourseSession(
                    id = session.id,
                    courseId = courseId,
                    dayOfWeek = session.dayOfWeek,
                    startPeriod = startPeriod,
                    endPeriod = endPeriod,
                    room = session.room.trim(),
                    teacher = session.teacher.trim(),
                    startMinute = session.customStartTime
                        .takeIf(String::isNotBlank)
                        ?.let(::parseMinute),
                    endMinute = session.customEndTime
                        .takeIf(String::isNotBlank)
                        ?.let(::parseMinute),
                ),
                weeks = session.selectedWeeks
                    .distinct()
                    .sorted()
                    .map { week -> SessionWeek(session.id, week) },
            )
        },
    )
}

internal fun defaultEditorSession(weekCount: Int): CourseEditorSessionForm =
    CourseEditorSessionForm(
        id = "session-${System.nanoTime()}",
        dayOfWeek = 1,
        startPeriod = "1",
        endPeriod = "1",
        room = "",
        teacher = "",
        selectedWeeks = (1..weekCount).toList(),
        customStartTime = "",
        customEndTime = "",
    )

private fun formatMinute(value: Int): String =
    String.format(Locale.ROOT, "%02d:%02d", value / 60, value % 60)

private fun parseMinute(value: String): Int? {
    val parts = value.trim().split(":")
    if (parts.size != 2) return null
    val hour = parts[0].toIntOrNull() ?: return null
    val minute = parts[1].toIntOrNull() ?: return null
    if (hour !in 0..23 || minute !in 0..59) return null
    return hour * 60 + minute
}
