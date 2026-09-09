package io.github.mxwf.weeko.feature.coursedetail

import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color

/** Immutable presentation state shared by the real route and Preview-only samples. */
@Immutable
sealed interface CourseDetailUiState {
    @Immutable
    data object Loading : CourseDetailUiState

    @Immutable
    data class Content(
        val courseName: String,
        val courseColor: Color,
        val room: String,
        val teacher: String,
        val dayOfWeek: String,
        val timeRange: String,
        val periods: String,
        val weeks: String,
        val note: String,
    ) : CourseDetailUiState

    @Immutable
    data object NotFound : CourseDetailUiState

    @Immutable
    data class Error(val message: String) : CourseDetailUiState
}
