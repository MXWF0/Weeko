package io.github.mxwf.weeko.designsystem

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.EventNote
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp

@Composable
fun WeekoButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    Button(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.sizeIn(minHeight = 48.dp),
        shape = MaterialTheme.shapes.medium,
        contentPadding = ButtonDefaults.ContentPadding,
    ) {
        Text(text = text)
    }
}

@Composable
fun WeekoOutlinedButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
) {
    OutlinedButton(
        onClick = onClick,
        enabled = enabled,
        modifier = modifier.sizeIn(minHeight = 48.dp),
        shape = MaterialTheme.shapes.medium,
    ) {
        Text(text = text)
    }
}

@Composable
fun WeekoCard(
    modifier: Modifier = Modifier,
    containerColor: Color = MaterialTheme.colorScheme.surfaceContainerLow,
    contentColor: Color = MaterialTheme.colorScheme.onSurface,
    onClick: (() -> Unit)? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    val clickHandler = onClick
    if (clickHandler == null) {
        Card(
            modifier = modifier,
            shape = MaterialTheme.shapes.medium,
            colors = CardDefaults.cardColors(
                containerColor = containerColor,
                contentColor = contentColor,
            ),
            content = { Column(content = content) },
        )
    } else {
        Card(
            onClick = clickHandler,
            modifier = modifier,
            shape = MaterialTheme.shapes.medium,
            colors = CardDefaults.cardColors(
                containerColor = containerColor,
                contentColor = contentColor,
            ),
            content = { Column(content = content) },
        )
    }
}

@Composable
fun WeekoCourseCard(
    name: String,
    courseColor: Color,
    modifier: Modifier = Modifier,
    room: String? = null,
    teacher: String? = null,
    time: String? = null,
    onClick: (() -> Unit)? = null,
) {
    val readableContentColor = if (courseColor.luminance() > 0.52f) {
        Color(0xFF17202A)
    } else {
        Color.White
    }

    WeekoCard(
        modifier = modifier,
        containerColor = courseColor,
        contentColor = readableContentColor,
        onClick = onClick,
    ) {
        Column(
            modifier = Modifier.padding(WeekoSpacing.current.md),
            verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.xs),
        ) {
            Text(text = name, style = MaterialTheme.typography.titleMedium)
            listOfNotNull(time, room, teacher).forEach { detail ->
                Text(text = detail, style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Composable
fun WeekoDialog(
    visible: Boolean,
    title: String,
    message: String,
    confirmLabel: String,
    onConfirm: () -> Unit,
    onDismissRequest: () -> Unit,
    dismissLabel: String? = null,
) {
    if (!visible) return

    AlertDialog(
        onDismissRequest = onDismissRequest,
        title = { Text(text = title) },
        text = { Text(text = message) },
        confirmButton = {
            TextButton(onClick = onConfirm) {
                Text(text = confirmLabel)
            }
        },
        dismissButton = dismissLabel?.let { label ->
            {
                TextButton(onClick = onDismissRequest) {
                    Text(text = label)
                }
            }
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeekoBottomSheet(
    visible: Boolean,
    onDismissRequest: () -> Unit,
    title: String? = null,
    content: @Composable ColumnScope.() -> Unit,
) {
    if (!visible) return

    ModalBottomSheet(
        onDismissRequest = onDismissRequest,
        shape = MaterialTheme.shapes.extraLarge,
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(
                    horizontal = WeekoSpacing.current.page,
                    vertical = WeekoSpacing.current.md,
                ),
            verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
            content = {
                title?.let { Text(text = it, style = MaterialTheme.typography.titleLarge) }
                content()
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeekoToolbar(
    title: String,
    modifier: Modifier = Modifier,
    onNavigationClick: (() -> Unit)? = null,
    navigationContentDescription: String = "返回",
    actions: @Composable androidx.compose.foundation.layout.RowScope.() -> Unit = {},
) {
    TopAppBar(
        title = { Text(text = title) },
        modifier = modifier,
        navigationIcon = {
            onNavigationClick?.let { onClick ->
                IconButton(
                    onClick = onClick,
                    modifier = Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp),
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                        contentDescription = navigationContentDescription,
                    )
                }
            }
        },
        actions = actions,
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = MaterialTheme.colorScheme.surface,
            titleContentColor = MaterialTheme.colorScheme.onSurface,
        ),
    )
}

@Composable
fun WeekoEmptyState(
    title: String,
    message: String,
    modifier: Modifier = Modifier,
    icon: ImageVector = Icons.AutoMirrored.Outlined.EventNote,
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(WeekoSpacing.current.xl),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.md),
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.primary,
            modifier = Modifier.size(40.dp),
        )
        Text(text = title, style = MaterialTheme.typography.titleMedium)
        Text(
            text = message,
            style = MaterialTheme.typography.bodyMedium,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (actionLabel != null && onAction != null) {
            WeekoButton(text = actionLabel, onClick = onAction)
        }
    }
}

@Composable
fun WeekoLoading(
    modifier: Modifier = Modifier,
    loadingDescription: String = "正在加载",
    message: String? = null,
) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) {
                contentDescription = loadingDescription
            },
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(WeekoSpacing.current.sm),
    ) {
        CircularProgressIndicator(modifier = Modifier.size(32.dp))
        message?.let {
            Text(
                text = it,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}
