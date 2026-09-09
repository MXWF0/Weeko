package io.github.mxwf.weeko.feature.editor

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.ViewModelProvider
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import io.github.mxwf.weeko.data.RoomWeekoRepository
import io.github.mxwf.weeko.database.WeekoDatabase
import io.github.mxwf.weeko.designsystem.WeekoTheme
import io.github.mxwf.weeko.feature.coursedetail.EXTRA_COURSE_ID

/** Full-screen editor host; the detail page remains a ModalBottomSheet. */
class CourseEditorActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val courseId = intent.getStringExtra(EXTRA_COURSE_ID)
            ?.takeIf(String::isNotBlank)
        if (courseId == null) {
            finish()
            return
        }

        val repository = RoomWeekoRepository(
            WeekoDatabase.build(applicationContext),
        )
        val viewModel = ViewModelProvider(
            this,
            CourseEditorViewModelFactory(courseId, repository),
        )[CourseEditorViewModel::class.java]

        setContent {
            WeekoTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    CourseEditorRoute(
                        viewModel = viewModel,
                        onSaved = {
                            setResult(RESULT_OK)
                            finish()
                        },
                        onCancel = ::finish,
                    )
                }
            }
        }
    }
}
