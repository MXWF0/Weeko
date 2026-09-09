package io.github.mxwf.weeko.feature.coursedetail

import io.github.mxwf.weeko.data.CourseDetailRepository
import io.github.mxwf.weeko.model.CourseDetailRecord
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.async
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class CourseDetailViewModelTest {
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
    fun missingCourseProducesNotFound() = runTest {
        val repository = FakeCourseDetailRepository(null)
        val viewModel = CourseDetailViewModel("missing", repository)

        advanceUntilIdle()

        assertEquals(CourseDetailUiState.NotFound, viewModel.uiState.value)
    }

    @Test
    fun repositoryFailureProducesError() = runTest {
        val repository = object : CourseDetailRepository {
            override fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?> = flow {
                throw IllegalStateException("database unavailable")
            }

            override suspend fun deleteCourse(courseId: String): Boolean = true
        }
        val viewModel = CourseDetailViewModel("course-1", repository)

        assertEquals(CourseDetailUiState.Loading, viewModel.uiState.value)
        advanceUntilIdle()

        assertEquals(CourseDetailUiState.Error("database unavailable"), viewModel.uiState.value)
    }

    @Test
    fun editAndDeleteClicksAreEventsAndDeleteWaitsForConfirmation() = runTest {
        val repository = FakeCourseDetailRepository(null)
        val viewModel = CourseDetailViewModel("course-1", repository)
        val events = mutableListOf<CourseDetailEvent>()
        val collector = launch(start = CoroutineStart.UNDISPATCHED) {
            viewModel.events.first { event ->
                events += event
                events.size == 2
            }
        }

        viewModel.onEditClicked()
        viewModel.onDeleteClicked()
        advanceUntilIdle()

        assertEquals(
            listOf(
                CourseDetailEvent.EditRequested,
                CourseDetailEvent.DeleteConfirmationRequested,
            ),
            events,
        )
        assertEquals(0, repository.deleteCalls)
        collector.cancel()

        val deletedEvent = async(start = CoroutineStart.UNDISPATCHED) {
            viewModel.events.first()
        }
        viewModel.confirmDelete()
        advanceUntilIdle()

        assertEquals(1, repository.deleteCalls)
        assertEquals(CourseDetailEvent.Deleted, deletedEvent.await())
    }

    private class FakeCourseDetailRepository(initial: CourseDetailRecord?) : CourseDetailRepository {
        private val record = MutableStateFlow(initial)
        var deleteCalls: Int = 0

        override fun observeCourseDetail(courseId: String): Flow<CourseDetailRecord?> = record

        override suspend fun deleteCourse(courseId: String): Boolean {
            deleteCalls += 1
            return true
        }
    }
}
