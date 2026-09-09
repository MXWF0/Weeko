package io.github.mxwf.weeko.feature.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import io.github.mxwf.weeko.designsystem.WeekoButton
import io.github.mxwf.weeko.designsystem.WeekoCard
import io.github.mxwf.weeko.designsystem.WeekoEmptyState
import io.github.mxwf.weeko.designsystem.WeekoLoading
import io.github.mxwf.weeko.designsystem.WeekoSpacing
import io.github.mxwf.weeko.designsystem.WeekoTheme
import io.github.mxwf.weeko.designsystem.WeekoToolbar
import io.github.mxwf.weeko.designsystem.WeekoCoursePalette

@Composable
fun CourseEditorRoute(
    viewModel: CourseEditorViewModel,
    onSaved: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(viewModel) {
        viewModel.events.collect { event ->
            when (event) {
                CourseEditorEvent.Saved -> onSaved()
                CourseEditorEvent.CancelRequested -> onCancel()
            }
        }
    }

    when (val state = uiState) {
        CourseEditorUiState.Loading -> WeekoLoading(modifier = modifier)
        CourseEditorUiState.NotFound -> WeekoEmptyState(
            modifier = modifier,
            title = "找不到课程",
            message = "这门课程可能已经被删除。",
        )
        is CourseEditorUiState.Error -> EditorError(
            message = state.message,
            onBack = viewModel::onCancelClicked,
            modifier = modifier,
        )
        is CourseEditorUiState.Content -> CourseEditorScreen(
            form = state.form,
            isSaving = state.isSaving,
            errorMessage = state.errorMessage,
            onNameChanged = viewModel::onNameChanged,
            onCourseCodeChanged = viewModel::onCourseCodeChanged,
            onCreditChanged = viewModel::onCreditChanged,
            onNoteChanged = viewModel::onNoteChanged,
            onColorSelected = viewModel::onColorSelected,
            onSessionChanged = viewModel::onSessionChanged,
            onAddSession = viewModel::addSession,
            onRemoveSession = viewModel::removeSession,
            onSave = viewModel::onSaveClicked,
            onCancel = viewModel::onCancelClicked,
            modifier = modifier,
        )
    }
}

@Composable
private fun EditorError(
    message: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier.padding(WeekoSpacing.current.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
    ) {
        Text(text = message, color = MaterialTheme.colorScheme.error)
        TextButton(onClick = onBack, modifier = Modifier.sizeIn(minHeight = 48.dp)) {
            Text("返回")
        }
    }
}

@Composable
private fun CourseEditorScreen(
    form: CourseEditorForm,
    isSaving: Boolean,
    errorMessage: String?,
    onNameChanged: (String) -> Unit,
    onCourseCodeChanged: (String) -> Unit,
    onCreditChanged: (String) -> Unit,
    onNoteChanged: (String) -> Unit,
    onColorSelected: (Long) -> Unit,
    onSessionChanged: (Int, CourseEditorSessionForm) -> Unit,
    onAddSession: () -> Unit,
    onRemoveSession: (Int) -> Unit,
    onSave: () -> Unit,
    onCancel: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val enabled = !isSaving
    Scaffold(
        modifier = modifier,
        topBar = {
            WeekoToolbar(
                title = "编辑课程",
                onNavigationClick = onCancel,
            )
        },
        bottomBar = {
            Surface(
                tonalElevation = 3.dp,
                shadowElevation = 1.dp,
            ) {
                WeekoButton(
                    text = if (isSaving) "保存中…" else "保存课程",
                    onClick = onSave,
                    enabled = enabled,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(
                            horizontal = WeekoSpacing.current.page,
                            vertical = WeekoSpacing.current.sm,
                        ),
                )
            }
        },
    ) { contentPadding ->
        LazyColumn(
            modifier = Modifier.padding(contentPadding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(
                horizontal = WeekoSpacing.current.page,
                vertical = WeekoSpacing.current.md,
            ),
            verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
        ) {
            item { EditorSectionTitle("基础信息") }
            item {
                OutlinedTextField(
                    value = form.name,
                    onValueChange = onNameChanged,
                    enabled = enabled,
                    label = { Text("课程名称") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            item {
                Row(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm)) {
                    OutlinedTextField(
                        value = form.courseCode,
                        onValueChange = onCourseCodeChanged,
                        enabled = enabled,
                        label = { Text("课程号") },
                        singleLine = true,
                        modifier = Modifier.weight(1f),
                    )
                    OutlinedTextField(
                        value = form.credit,
                        onValueChange = onCreditChanged,
                        enabled = enabled,
                        label = { Text("学分") },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.width(120.dp),
                    )
                }
            }

            item { EditorSectionTitle("上课时间与周次") }
            itemsIndexed(form.sessions, key = { _, session -> session.id }) { index, session ->
                SessionEditorCard(
                    index = index,
                    session = session,
                    weekCount = form.weekCount,
                    enabled = enabled,
                    canRemove = form.sessions.size > 1,
                    onChanged = { onSessionChanged(index, it) },
                    onRemove = { onRemoveSession(index) },
                )
            }
            item {
                TextButton(
                    onClick = onAddSession,
                    enabled = enabled,
                    modifier = Modifier.sizeIn(minHeight = 48.dp),
                ) {
                    Text("添加上课安排")
                }
            }

            item { EditorSectionTitle("外观") }
            item {
                WeekoCard(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier.padding(WeekoSpacing.current.md),
                        verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm),
                    ) {
                        Text("课程颜色", style = MaterialTheme.typography.titleMedium)
                        LazyRow(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs)) {
                            items(WeekoCoursePalette.all.indices.toList()) { index ->
                                val selected = Math.floorMod(
                                    form.colorSeed,
                                    WeekoCoursePalette.all.size.toLong(),
                                ).toInt() == index
                                FilterChip(
                                    selected = selected,
                                    onClick = { onColorSelected(index.toLong()) },
                                    label = { Text("颜色 ${index + 1}") },
                                    leadingIcon = {
                                        ColorDot(WeekoCoursePalette.all[index])
                                    },
                                )
                            }
                        }
                    }
                }
            }

            item { EditorSectionTitle("提醒") }
            item {
                WeekoCard(modifier = Modifier.fillMaxWidth()) {
                    Column(
                        modifier = Modifier.padding(WeekoSpacing.current.md),
                        verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs),
                    ) {
                        Text("课程提醒", style = MaterialTheme.typography.titleMedium)
                        Text(
                            text = "提醒数据模型尚未接入，保存课程时不会修改提醒设置。",
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }

            item { EditorSectionTitle("备注") }
            item {
                OutlinedTextField(
                    value = form.note,
                    onValueChange = onNoteChanged,
                    enabled = enabled,
                    label = { Text("备注") },
                    minLines = 3,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
            errorMessage?.let { message ->
                item {
                    Text(
                        text = message,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
    }
}

@Composable
private fun SessionEditorCard(
    index: Int,
    session: CourseEditorSessionForm,
    weekCount: Int,
    enabled: Boolean,
    canRemove: Boolean,
    onChanged: (CourseEditorSessionForm) -> Unit,
    onRemove: () -> Unit,
) {
    WeekoCard(modifier = Modifier.fillMaxWidth()) {
        Column(
            modifier = Modifier.padding(WeekoSpacing.current.md),
            verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text("上课安排 ${index + 1}", style = MaterialTheme.typography.titleMedium)
                if (canRemove) {
                    TextButton(
                        onClick = onRemove,
                        enabled = enabled,
                        modifier = Modifier.sizeIn(minHeight = 48.dp),
                    ) {
                        Text("移除")
                    }
                }
            }
            Text("星期", style = MaterialTheme.typography.labelLarge)
            LazyRow(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs)) {
                items(DAY_NAMES.indices.toList()) { dayIndex ->
                    val day = dayIndex + 1
                    FilterChip(
                        selected = session.dayOfWeek == day,
                        onClick = { onChanged(session.copy(dayOfWeek = day)) },
                        enabled = enabled,
                        label = { Text(DAY_NAMES[dayIndex]) },
                    )
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm)) {
                OutlinedTextField(
                    value = session.startPeriod,
                    onValueChange = { onChanged(session.copy(startPeriod = it)) },
                    enabled = enabled,
                    label = { Text("起始节次") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                )
                OutlinedTextField(
                    value = session.endPeriod,
                    onValueChange = { onChanged(session.copy(endPeriod = it)) },
                    enabled = enabled,
                    label = { Text("结束节次") },
                    singleLine = true,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                )
            }
            OutlinedTextField(
                value = session.room,
                onValueChange = { onChanged(session.copy(room = it)) },
                enabled = enabled,
                label = { Text("教室") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            OutlinedTextField(
                value = session.teacher,
                onValueChange = { onChanged(session.copy(teacher = it)) },
                enabled = enabled,
                label = { Text("教师") },
                singleLine = true,
                modifier = Modifier.fillMaxWidth(),
            )
            Text("周次（本学期共 $weekCount 周）", style = MaterialTheme.typography.labelLarge)
            LazyRow(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs)) {
                items((1..weekCount).toList()) { week ->
                    FilterChip(
                        selected = week in session.selectedWeeks,
                        onClick = {
                            val weeks = if (week in session.selectedWeeks) {
                                session.selectedWeeks - week
                            } else {
                                (session.selectedWeeks + week).sorted()
                            }
                            onChanged(session.copy(selectedWeeks = weeks))
                        },
                        enabled = enabled,
                        label = { Text("$week") },
                    )
                }
            }
            Text("自定义时间（可选，格式 HH:MM）", style = MaterialTheme.typography.labelLarge)
            Row(horizontalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm)) {
                OutlinedTextField(
                    value = session.customStartTime,
                    onValueChange = { onChanged(session.copy(customStartTime = it)) },
                    enabled = enabled,
                    label = { Text("开始时间") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                OutlinedTextField(
                    value = session.customEndTime,
                    onValueChange = { onChanged(session.copy(customEndTime = it)) },
                    enabled = enabled,
                    label = { Text("结束时间") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun EditorSectionTitle(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleLarge,
        color = MaterialTheme.colorScheme.onSurface,
    )
}

@Composable
private fun ColorDot(color: Color) {
    androidx.compose.foundation.layout.Box(
        modifier = Modifier
            .size(18.dp)
            .background(color, CircleShape),
    )
}

private val DAY_NAMES = listOf("周一", "周二", "周三", "周四", "周五", "周六", "周日")

@Preview(name = "课程编辑", showBackground = true, widthDp = 412, heightDp = 900)
@Composable
private fun CourseEditorPreview() {
    WeekoTheme {
        CourseEditorScreen(
            form = CourseEditorForm(
                courseId = "preview-course",
                scheduleId = "preview-schedule",
                name = "数据库原理",
                courseCode = "CS-204",
                credit = "3",
                colorSeed = 1,
                note = "期末项目在第 16 周提交。",
                weekCount = 16,
                sessions = listOf(
                    CourseEditorSessionForm(
                        id = "preview-session",
                        dayOfWeek = 2,
                        startPeriod = "3",
                        endPeriod = "4",
                        room = "B204",
                        teacher = "赵老师",
                        selectedWeeks = (1..16).toList(),
                        customStartTime = "10:00",
                        customEndTime = "11:30",
                    ),
                ),
            ),
            isSaving = false,
            errorMessage = null,
            onNameChanged = {},
            onCourseCodeChanged = {},
            onCreditChanged = {},
            onNoteChanged = {},
            onColorSelected = {},
            onSessionChanged = { _, _ -> },
            onAddSession = {},
            onRemoveSession = {},
            onSave = {},
            onCancel = {},
        )
    }
}
