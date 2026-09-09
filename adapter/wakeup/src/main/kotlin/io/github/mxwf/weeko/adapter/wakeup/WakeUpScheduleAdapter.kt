package io.github.mxwf.weeko.adapter.wakeup

import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

/**
 * Minimal, source-independent reader for the WakeUp 6.0.x backup format.
 *
 * The legacy file is UTF-8 and contains five newline-delimited JSON values:
 * time-table compatibility object, time-detail list, table compatibility object,
 * course-base list, and course-detail list.
 */
class WakeUpScheduleAdapter(
    private val gson: Gson = Gson(),
) {
    fun parse(text: String): WakeUpScheduleDraft {
        val lines = text.trimEnd('\r', '\n').lineSequence().map { it.removeSuffix("\r") }.toList()
        require(lines.size >= FORMAT_LINE_COUNT) {
            "WakeUp backup must contain at least $FORMAT_LINE_COUNT JSON lines"
        }

        val timeTable = gson.fromJson(lines[0], TimeTableCompat::class.java)
        val timeDetails = gson.fromJson<List<TimeDetail>>(lines[1], timeDetailsType)
        val table = gson.fromJson(lines[2], TableCompat::class.java)
        val courses = gson.fromJson<List<CourseBase>>(lines[3], courseBaseType)
        val sessions = gson.fromJson<List<CourseDetail>>(lines[4], courseDetailType)

        require(timeTable.name.isNotBlank()) { "WakeUp time-table name is blank" }
        require(table.tableName.isNotBlank()) { "WakeUp table name is blank" }
        require(table.timeTable == timeTable.id) {
            "WakeUp table/time-table ids do not match"
        }

        return WakeUpScheduleDraft(
            timeTable = timeTable,
            timeDetails = timeDetails,
            table = table,
            courses = courses,
            sessions = sessions,
            ignoredTrailingLines = lines.drop(FORMAT_LINE_COUNT).filter(String::isNotEmpty),
        )
    }

    private companion object {
        const val FORMAT_LINE_COUNT = 5
        val timeDetailsType = object : TypeToken<List<TimeDetail>>() {}.type
        val courseBaseType = object : TypeToken<List<CourseBase>>() {}.type
        val courseDetailType = object : TypeToken<List<CourseDetail>>() {}.type
    }
}
