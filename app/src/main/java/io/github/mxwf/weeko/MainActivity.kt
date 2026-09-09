package io.github.mxwf.weeko

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.lifecycle.ViewModelProvider
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import io.github.mxwf.weeko.data.RoomWeekoRepository
import io.github.mxwf.weeko.database.WeekoDatabase
import io.github.mxwf.weeko.feature.coursedetail.CourseDetailPreviewActivity
import io.github.mxwf.weeko.feature.coursedetail.CourseDetailRoute
import io.github.mxwf.weeko.feature.coursedetail.CourseDetailViewModel
import io.github.mxwf.weeko.feature.coursedetail.CourseDetailViewModelFactory
import io.github.mxwf.weeko.feature.coursedetail.EXTRA_COURSE_ID
import io.github.mxwf.weeko.designsystem.DesignSystemPreviewActivity
import io.github.mxwf.weeko.designsystem.WeekoTheme
import io.github.mxwf.weeko.feature.editor.CourseEditorActivity

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val courseId = intent.getStringExtra(EXTRA_COURSE_ID)
            ?.takeIf(String::isNotBlank)
        if (courseId != null) {
            showCourseDetail(courseId)
        } else {
            showBaseline()
        }
    }

    private fun showCourseDetail(courseId: String) {
        val repository = RoomWeekoRepository(
            WeekoDatabase.build(applicationContext),
        )
        val viewModel = ViewModelProvider(
            this,
            CourseDetailViewModelFactory(courseId, repository),
        )[CourseDetailViewModel::class.java]

        setContent {
            WeekoTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    CourseDetailRoute(
                        viewModel = viewModel,
                        onDismissRequest = ::finish,
                        onEdit = {
                            startActivity(
                                Intent(this@MainActivity, CourseEditorActivity::class.java)
                                    .putExtra(EXTRA_COURSE_ID, courseId),
                            )
                        },
                    )
                }
            }
        }
    }

    private fun showBaseline() {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 32)
        }
        content.addView(
            TextView(this).apply {
                text = getString(R.string.baseline_message) +
                    "\n\n" +
                    getString(R.string.about_title) +
                    "\n" +
                    getString(R.string.about_body)
                textSize = 18f
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f,
            ),
        )
        content.addView(
            Button(this).apply {
                text = getString(R.string.design_system_button)
                setOnClickListener {
                    startActivity(Intent(this@MainActivity, DesignSystemPreviewActivity::class.java))
                }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        content.addView(
            Button(this).apply {
                text = getString(R.string.course_detail_button)
                setOnClickListener {
                    startActivity(Intent(this@MainActivity, CourseDetailPreviewActivity::class.java))
                }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        setContentView(content)
    }
}
