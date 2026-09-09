package io.github.mxwf.weeko.feature.editor

import io.github.mxwf.weeko.data.CourseEditorRepository
import io.github.mxwf.weeko.model.Course
import io.github.mxwf.weeko.model.CourseDetailRecord
import io.github.mxwf.weeko.model.CourseSession
import io.github.mxwf.weeko.model.CourseSessionRecord
import io.github.mxwf.weeko.model.SessionWeek
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)
class CourseEditorViewModelTest {
    private val dispatcher = StandardTestDispatcher()

    @Before
    fun setUp() {
        Dispatchers.setMain(dispatcher)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun loadsContentAndRejectsInvalidSave() = runTest {
        val repository = FakeRepository(sampleRecord())
        val viewModel = CourseEditorViewModel("course-1", repository)
        advanceUntilIdle()

        assertTrue(viewModel.uiState.value is CourseEditorUiState.Content)
        viewModel.onNameChanged("")
        viewModel.onSaveClicked()
        advanceUntilIdle()

        val state = viewModel.uiState.value as CourseEditorUiState.Content
        assertEquals("课程名称不能为空", state.errorMessage)
        assertEquals(0, repository.saveCalls)
    }

    @Test
    fun missingCourseProducesNotFound() = runTest {
        val viewModel = CourseEditorViewModel("missing", FakeRepository(null))

        advanceUntilIdle()

        assertEquals(CourseEditorUiState.NotFound, viewModel.uiState.value)
    }

    @Test
    fun repositoryFailureProducesError() = runTest {
        val repository = object : CourseEditorRepository {
            override fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?> = flow {
                throw IllegalStateException("database unavailable")
            }

            override suspend fun saveCourse(
                course: Course,
                sessions: List<CourseSessionRecord>,
            ): Boolean = true
        }
        val viewModel = CourseEditorViewModel("course-1", repository)

        advanceUntilIdle()

        assertEquals(
            CourseEditorUiState.Error("database unavailable"),
            viewModel.uiState.value,
        )
    }

    @Test
    fun validSaveEmitsSavedEventWithUpdatedCourse() = runTest {
        val repository = FakeRepository(sampleRecord())
        val viewModel = CourseEditorViewModel("course-1", repository)
        advanceUntilIdle()
        val event = async(start = CoroutineStart.UNDISPATCHED) {
            viewModel.events.first()
        }

        viewModel.onNameChanged("新的课程名称")
        viewModel.onSaveClicked()
        advanceUntilIdle()

        assertEquals(CourseEditorEvent.Saved, event.await())
        assertEquals(1, repository.saveCalls)
        assertEquals("新的课程名称", repository.savedCourse?.name)
    }

    @Test
    fun cancelIsAnEvent() = runTest {
        val repository = FakeRepository(sampleRecord())
        val viewModel = CourseEditorViewModel("course-1", repository)
        val event = async(start = CoroutineStart.UNDISPATCHED) {
            viewModel.events.first()
        }

        viewModel.onCancelClicked()
        advanceUntilIdle()

        assertEquals(CourseEditorEvent.CancelRequested, event.await())
    }

    private class FakeRepository(initial: CourseDetailRecord?) : CourseEditorRepository {
        private val record = MutableStateFlow(initial)
        var saveCalls: Int = 0
        var savedCourse: Course? = null

        override fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?> = record

        override suspend fun saveCourse(
            course: Course,
            sessions: List<CourseSessionRecord>,
        ): Boolean {
            saveCalls += 1
            savedCourse = course
            return true
        }
    }

    private fun sampleRecord() = CourseDetailRecord(
        course = Course("course-1", "schedule-1", "旧课程", 1),
        sessions = listOf(
            CourseSessionRecord(
                session = CourseSession(
                    id = "session-1",
                    courseId = "course-1",
                    dayOfWeek = 1,
                    startPeriod = 1,
                    endPeriod = 1,
                ),
                weeks = listOf(SessionWeek("session-1", 1)),
            ),
        ),
        timeSlots = emptyList(),
    )
}
