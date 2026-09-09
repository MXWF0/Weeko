package io.github.mxwf.weeko.adapter.wakeup

/** The decoded, write-free representation of one WakeUp backup. */
data class WakeUpScheduleDraft(
    val timeTable: TimeTableCompat,
    val timeDetails: List<TimeDetail>,
    val table: TableCompat,
    val courses: List<CourseBase>,
    val sessions: List<CourseDetail>,
    val ignoredTrailingLines: List<String> = emptyList(),
)

data class TimeTableCompat(
    var id: Int = 0,
    var name: String = "",
    var sameLen: Boolean = true,
    var courseLen: Int = 50,
    var sameBreakLen: Boolean = false,
    var theBreakLen: Int = 10,
)

data class TimeDetail(
    var node: Int = 0,
    var startTime: String = "",
    var endTime: String = "",
    var timeTable: Int = 0,
)

data class TableCompat(
    var id: Int = 0,
    var tableName: String = "",
    var nodes: Int = 20,
    var background: String = "",
    var timeTable: Int = 0,
    var startDate: String = "",
    var maxWeek: Int = 20,
    var itemHeight: Int = 64,
    var itemAlpha: Int = 50,
    var itemTextSize: Int = 12,
    var widgetItemHeight: Int = 64,
    var widgetItemAlpha: Int = 50,
    var widgetItemTextSize: Int = 12,
    var strokeColor: Int = -2130706433,
    var widgetStrokeColor: Int = -2130706433,
    var textColor: Int = -16777216,
    var widgetTextColor: Int = -16777216,
    var courseTextColor: Int = -1,
    var widgetCourseTextColor: Int = -1,
    var showSat: Boolean = true,
    var showSun: Boolean = true,
    var sundayFirst: Boolean = false,
    var showOtherWeekCourse: Boolean = true,
    var showTime: Boolean = false,
    var type: Int = 0,
)

data class CourseBase(
    var id: Int = 0,
    var courseName: String = "",
    var color: String = "",
    var tableId: Int = 0,
    var note: String = "",
    var credit: Float = 0f,
)

data class CourseDetail(
    var id: Int = 0,
    var day: Int = 0,
    var room: String? = null,
    var teacher: String? = null,
    var startNode: Int = 0,
    var step: Int = 0,
    var startWeek: Int = 0,
    var endWeek: Int = 0,
    var type: Int = 0,
    var tableId: Int = 0,
    var level: Int = 0,
    var ownTime: Boolean = false,
    var startTime: String = "",
    var endTime: String = "",
)
