package io.github.mxwf.weeko.feature.coursedetail

import io.github.mxwf.weeko.designsystem.WeekoCoursePalette
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.TimeSlot
import java.util.Locale

internal fun CourseDetailRecord.toUiState(): CourseDetailUiState.Content {
    val firstSession = sessions.firstOrNull()
    val dayText = sessions
        .map(CourseSessionRecord::session)
        .map { dayName(it.dayOfWeek) }
        .distinct()
        .joinToString("、")
        .ifBlank { "未设置星期" }
    val periodText = sessions
        .map(CourseSessionRecord::session)
        .map { "第 ${it.startPeriod}–${it.endPeriod} 节" }
        .distinct()
        .joinToString("、")
        .ifBlank { "未设置节次" }
    val weekText = sessions
        .flatMap(CourseSessionRecord::weeks)
        .map { it.weekIndex }
        .distinct()
        .sorted()
        .joinWeeks()
        .ifBlank { "未设置周次" }
    val timeText = sessions
        .mapNotNull { session -> session.session.customTimeOrNull() ?: timeFor(session, timeSlots) }
        .distinct()
        .joinToString("、")
        .ifBlank { "未设置时间" }

    return CourseDetailUiState.Content(
        courseName = course.name,
        courseColor = WeekoCoursePalette.fromSeed(course.colorSeed),
        room = sessions.map { it.session.room }.firstOrNull(String::isNotBlank).orEmpty(),
        teacher = sessions.map { it.session.teacher }.firstOrNull(String::isNotBlank).orEmpty(),
        dayOfWeek = dayText,
        timeRange = timeText,
        periods = periodText,
        weeks = weekText,
        note = course.note,
    )
}

private fun io.github.mxwf.weeko.model.CourseSession.customTimeOrNull(): String? {
    val start = startMinute ?: return null
    val end = endMinute ?: return null
    return "${formatMinute(start)}–${formatMinute(end)}"
}

private fun timeFor(session: CourseSessionRecord, slots: List<TimeSlot>): String? {
    val start = slots.firstOrNull { it.periodIndex == session.session.startPeriod }?.startMinute ?: return null
    val end = slots.firstOrNull { it.periodIndex == session.session.endPeriod }?.endMinute ?: return null
    return "${formatMinute(start)}–${formatMinute(end)}"
}

private fun formatMinute(value: Int): String = String.format(Locale.ROOT, "%02d:%02d", value / 60, value % 60)

private fun dayName(value: Int): String = when (value) {
    1 -> "星期一"
    2 -> "星期二"
    3 -> "星期三"
    4 -> "星期四"
    5 -> "星期五"
    6 -> "星期六"
    7 -> "星期日"
    else -> "星期$value"
}

private fun List<Int>.joinWeeks(): String {
    if (isEmpty()) return ""
    val weeks = this
    val ranges = buildList<String> {
        var start = weeks.first()
        var previous = start
        for (week in weeks.drop(1)) {
            if (week == previous + 1) {
                previous = week
            } else {
                add(if (start == previous) "$start" else "$start–$previous")
                start = week
                previous = week
            }
        }
        add(if (start == previous) "$start" else "$start–$previous")
    }
    return "第 ${ranges.joinToString("、")} 周"
}
