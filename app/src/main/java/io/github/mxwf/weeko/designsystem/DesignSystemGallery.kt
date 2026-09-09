package io.github.mxwf.weeko.designsystem

import android.content.res.Configuration
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun WeekoDesignSystemGallery(
    modifier: Modifier = Modifier,
    title: String = "Weeko Design System",
) {
    var dialogVisible by rememberSaveable { mutableStateOf(false) }
    var sheetVisible by rememberSaveable { mutableStateOf(false) }
    val spacing = WeekoSpacing.current

    Scaffold(
        modifier = modifier,
        topBar = { WeekoToolbar(title = title) },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxWidth()
                .padding(innerPadding),
            contentPadding = PaddingValues(
                horizontal = spacing.page,
                vertical = spacing.section,
            ),
            verticalArrangement = Arrangement.spacedBy(spacing.section),
        ) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(spacing.xs)) {
                    Text(
                        text = "组件预览",
                        style = MaterialTheme.typography.headlineSmall,
                    )
                    Text(
                        text = "Compose 与传统 View 共存的独立测试页面",
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            item {
                WeekoCard {
                    Column(
                        modifier = Modifier.padding(spacing.md),
                        verticalArrangement = Arrangement.spacedBy(spacing.xs),
                    ) {
                        Text(
                            text = "Tonal Surface Card",
                            style = MaterialTheme.typography.titleMedium,
                        )
                        Text(
                            text = "卡片使用主题 surface token，避免页面直接散落颜色。",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            }

            item {
                WeekoCourseCard(
                    name = "高等数学",
                    time = "周一 08:00–09:50",
                    room = "A101",
                    teacher = "张老师",
                    courseColor = WeekoCoursePalette.Blue,
                )
            }

            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(spacing.sm),
                ) {
                    WeekoButton(
                        text = "显示 Dialog",
                        onClick = { dialogVisible = true },
                        modifier = Modifier.weight(1f),
                    )
                    WeekoOutlinedButton(
                        text = "显示 Sheet",
                        onClick = { sheetVisible = true },
                        modifier = Modifier.weight(1f),
                    )
                }
            }

            item {
                WeekoEmptyState(
                    title = "还没有课程",
                    message = "导入或添加课程后，这里会显示你的今日安排。",
                    actionLabel = "添加示例课程",
                    onAction = {},
                )
            }

            item {
                WeekoCard {
                    WeekoLoading(message = "加载本地课表…")
                }
            }
        }
    }

    WeekoDialog(
        visible = dialogVisible,
        title = "Weeko Dialog",
        message = "这是一个可由旧 Activity 或新 Compose 页面复用的确认对话框。",
        confirmLabel = "知道了",
        dismissLabel = "取消",
        onConfirm = { dialogVisible = false },
        onDismissRequest = { dialogVisible = false },
    )

    WeekoBottomSheet(
        visible = sheetVisible,
        title = "Weeko Bottom Sheet",
        onDismissRequest = { sheetVisible = false },
    ) {
        Text(
            text = "详情内容可以逐步替换旧 XML 页面，而不改变数据层。",
            style = MaterialTheme.typography.bodyLarge,
        )
        WeekoButton(
            text = "关闭",
            onClick = { sheetVisible = false },
            modifier = Modifier.fillMaxWidth(),
        )
    }
}

@Preview(
    name = "Weeko Light",
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun WeekoLightPreview() {
    WeekoTheme(darkTheme = false, dynamicColor = false) {
        WeekoDesignSystemGallery()
    }
}

@Preview(
    name = "Weeko Dark",
    uiMode = Configuration.UI_MODE_NIGHT_YES,
    showBackground = true,
    widthDp = 375,
    heightDp = 812,
)
@Composable
private fun WeekoDarkPreview() {
    WeekoTheme(darkTheme = true, dynamicColor = false) {
        WeekoDesignSystemGallery()
    }
}

@Preview(
    name = "Weeko Landscape",
    showBackground = true,
    widthDp = 812,
    heightDp = 375,
)
@Composable
private fun WeekoLandscapePreview() {
    WeekoTheme(darkTheme = false, dynamicColor = false) {
        WeekoDesignSystemGallery()
    }
}
