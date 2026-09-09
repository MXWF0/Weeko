package io.github.mxwf.weeko.designsystem

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import io.github.mxwf.weeko.R

/** Manual gallery for the design system; existing View/XML screens remain untouched. */
class DesignSystemPreviewActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            WeekoTheme {
                WeekoDesignSystemGallery(title = getString(R.string.design_system_title))
            }
        }
    }
}
