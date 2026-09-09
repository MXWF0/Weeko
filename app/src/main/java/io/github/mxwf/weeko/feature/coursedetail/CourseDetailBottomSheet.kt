package io.github.mxwf.weeko.feature.coursedetail

import android.content.res.Configuration
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import io.github.mxwf.weeko.designsystem.WeekoSpacing
import io.github.mxwf.weeko.designsystem.WeekoTheme

/**
 * Presentation-only course detail sheet. It owns no state and performs no data access.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CourseDetailBottomSheet(
    visible: Boolean,
    uiState: CourseDetailUiState.Content,
    onDismissRequest: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (!visible) return

    val spacing = WeekoSpacing.current
    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        modifier = modifier,
        sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
        shape = MaterialTheme.shapes.extraLarge,
        containerColor = MaterialTheme.colorScheme.surface,
        tonalElevation = 2.dp,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = spacing.page, vertical = spacing.md),
            verticalArrangement = Arrangement.spacedBy(spacing.md),
        ) {
            CourseDetailHeader(uiState = uiState)

            WeekoCourseInfoCard(uiState = uiState)

            if (uiState.note.isNotBlank()) {
                WeekoNoteCard(note = uiState.note)
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(spacing.sm),
            ) {
                OutlinedButton(
                    onClick = onEdit,
                    modifier = Modifier
                        .weight(1f)
                        .sizeIn(minHeight = 48.dp),
                    shape = MaterialTheme.shapes.medium,
                ) {
                    Text(text = "编辑")
                }
                TextButton(
                    onClick = onDelete,
                    modifier = Modifier
                        .weight(1f)
                        .sizeIn(minHeight = 48.dp),
                    colors = ButtonDefaults.textButtonColors(
                        contentColor = MaterialTheme.colorScheme.error,
                    ),
                ) {
                    Text(text = "删除")
                }
            }
        }
    }
}

@Composable
private fun CourseDetailHeader(uiState: CourseDetailUiState.Content) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
    ) {
        Box(
            modifier = Modifier
                .sizeIn(minWidth = 8.dp, minHeight = 72.dp)
                .clip(MaterialTheme.shapes.small)
                .background(uiState.courseColor),
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs),
        ) {
            Text(
                text = uiState.courseName,
                style = MaterialTheme.typography.headlineSmall,
            )
            Text(
                text = uiState.room.ifBlank { "未设置教室" },
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun WeekoCourseInfoCard(uiState: CourseDetailUiState.Content) {
    WeekoSurfaceCard {
        CourseDetailRow(label = "教师", value = uiState.teacher)
        CourseDetailRow(label = "星期", value = uiState.dayOfWeek)
        CourseDetailRow(label = "时间", value = uiState.timeRange)
        CourseDetailRow(label = "节次", value = uiState.periods)
        CourseDetailRow(label = "周次", value = uiState.weeks)
    }
}

@Composable
private fun WeekoNoteCard(note: String) {
    WeekoSurfaceCard {
        Text(
            text = "备注",
            style = MaterialTheme.typography.titleMedium,
        )
        Text(
            text = note,
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@Composable
private fun WeekoSurfaceCard(content: @Composable ColumnScope.() -> Unit) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceContainerLow,
        tonalElevation = 0.dp,
        content = {
            Column(
                modifier = Modifier.padding(WeekoSpacing.current.md),
                verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm),
                content = content,
            )
        },
    )
}

@Composable
private fun CourseDetailRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
    ) {
        Text(
            text = label,
            modifier = Modifier.sizeIn(minWidth = 48.dp),
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = value,
            modifier = Modifier.weight(1f),
            style = MaterialTheme.typography.bodyLarge,
        )
    }
}

@Preview(
    name = "Course Detail Light",
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun CourseDetailLightPreview() {
    WeekoTheme(darkTheme = false, dynamicColor = false) {
        Surface {
            CourseDetailBottomSheet(
                visible = true,
                uiState = CourseDetailPreviewSamples.default,
                onDismissRequest = {},
                onEdit = {},
                onDelete = {},
            )
        }
    }
}

@Preview(
    name = "Course Detail Dark",
    uiMode = Configuration.UI_MODE_NIGHT_YES,
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun CourseDetailDarkPreview() {
    WeekoTheme(darkTheme = true, dynamicColor = false) {
        Surface {
            CourseDetailBottomSheet(
                visible = true,
                uiState = CourseDetailPreviewSamples.default,
                onDismissRequest = {},
                onEdit = {},
                onDelete = {},
            )
        }
    }
}

@Preview(
    name = "Course Detail Long Text",
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun CourseDetailLongTextPreview() {
    WeekoTheme(darkTheme = false, dynamicColor = false) {
        Surface {
            CourseDetailBottomSheet(
                visible = true,
                uiState = CourseDetailPreviewSamples.longText,
                onDismissRequest = {},
                onEdit = {},
                onDelete = {},
            )
        }
    }
}

@Preview(
    name = "Course Detail Empty Note",
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun CourseDetailEmptyNotePreview() {
    WeekoTheme(darkTheme = false, dynamicColor = false) {
        Surface {
            CourseDetailBottomSheet(
                visible = true,
                uiState = CourseDetailPreviewSamples.emptyNote,
                onDismissRequest = {},
                onEdit = {},
                onDelete = {},
            )
        }
    }
}
