package io.github.mxwf.weeko.feature.coursedetail

import io.github.mxwf.weeko.designsystem.WeekoCoursePalette

/** Sample-only values shared by previews and the internal prototype entry point. */
internal object CourseDetailPreviewSamples {
    val default = CourseDetailUiState.Content(
        courseName = "高等数学",
        courseColor = WeekoCoursePalette.Blue,
        room = "A101",
        teacher = "张老师",
        dayOfWeek = "星期一",
        timeRange = "08:00–09:50",
        periods = "第 1–2 节",
        weeks = "第 1–16 周",
        note = "记得携带作业本。",
    )

    val longText = CourseDetailUiState.Content(
        courseName = "现代大学英语综合能力与学术写作基础",
        courseColor = WeekoCoursePalette.Plum,
        room = "综合教学楼 B 区 1208 多媒体教室",
        teacher = "李老师、王老师（联合授课）",
        dayOfWeek = "星期三",
        timeRange = "14:00–17:25",
        periods = "第 5–8 节",
        weeks = "第 2–4、6–8、10–13 周",
        note = "本课程包含较长的说明文字，用于确认 Bottom Sheet 在小屏幕和大字号场景下仍然可以自然换行，不依赖截断。",
    )

    val emptyNote = default.copy(note = "")
}
