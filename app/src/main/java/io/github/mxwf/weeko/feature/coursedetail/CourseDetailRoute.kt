package io.github.mxwf.weeko.feature.coursedetail

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import io.github.mxwf.weeko.designsystem.WeekoDialog
import io.github.mxwf.weeko.designsystem.WeekoEmptyState
import io.github.mxwf.weeko.designsystem.WeekoLoading

/** Production presentation route. It receives a ViewModel and never touches Room directly. */
@Composable
fun CourseDetailRoute(
    viewModel: CourseDetailViewModel,
    onDismissRequest: () -> Unit,
    onEdit: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsState()
    var showDeleteConfirmation by rememberSaveable { mutableStateOf(false) }

    LaunchedEffect(viewModel) {
        viewModel.events.collect { event ->
            when (event) {
                CourseDetailEvent.EditRequested -> onEdit()
                CourseDetailEvent.DeleteConfirmationRequested -> {
                    showDeleteConfirmation = true
                }
                CourseDetailEvent.Deleted -> {
                    showDeleteConfirmation = false
                    onDismissRequest()
                }
                CourseDetailEvent.DeleteTargetMissing -> {
                    showDeleteConfirmation = false
                    onDismissRequest()
                }
            }
        }
    }

    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        when (val state = uiState) {
            CourseDetailUiState.Loading -> WeekoLoading()
            CourseDetailUiState.NotFound -> WeekoEmptyState(
                title = "找不到课程",
                message = "这门课程可能已经被删除。",
            )
            is CourseDetailUiState.Error -> Text(
                text = state.message,
                color = MaterialTheme.colorScheme.error,
            )
            is CourseDetailUiState.Content -> CourseDetailBottomSheet(
                visible = true,
                uiState = state,
                onDismissRequest = onDismissRequest,
                onEdit = viewModel::onEditClicked,
                onDelete = viewModel::onDeleteClicked,
            )
        }
    }

    WeekoDialog(
        visible = showDeleteConfirmation,
        title = "删除课程？",
        message = "删除后无法撤销，这门课程的所有上课安排都会被移除。",
        confirmLabel = "删除",
        dismissLabel = "取消",
        onConfirm = viewModel::confirmDelete,
        onDismissRequest = { showDeleteConfirmation = false },
    )
}

