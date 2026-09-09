package io.github.mxwf.weeko.feature.coursedetail

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import io.github.mxwf.weeko.designsystem.WeekoTheme

/** Internal test entry for the presentation-only course detail prototype. */
class CourseDetailPreviewActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WeekoTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    CourseDetailBottomSheet(
                        visible = true,
                        uiState = CourseDetailPreviewSamples.default,
                        onDismissRequest = ::finish,
                        onEdit = {},
                        onDelete = {},
                    )
                }
            }
        }
    }
}
