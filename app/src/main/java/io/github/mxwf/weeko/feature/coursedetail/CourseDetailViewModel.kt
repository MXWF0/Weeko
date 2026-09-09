package io.github.mxwf.weeko.feature.coursedetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import io.github.mxwf.weeko.data.CourseDetailRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

sealed interface CourseDetailEvent {
    data object EditRequested : CourseDetailEvent
    data object DeleteConfirmationRequested : CourseDetailEvent
    data object Deleted : CourseDetailEvent
    data object DeleteTargetMissing : CourseDetailEvent
}

class CourseDetailViewModel(
    private val courseId: String,
    private val repository: CourseDetailRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow<CourseDetailUiState>(CourseDetailUiState.Loading)
    val uiState: StateFlow<CourseDetailUiState> = _uiState.asStateFlow()

    private val _events = Channel<CourseDetailEvent>(capacity = Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    init {
        viewModelScope.launch {
            repository.observeCourseDetail(courseId)
                .map { record ->
                    record?.toUiState() ?: CourseDetailUiState.NotFound
                }
                .catch { error ->
                    _uiState.value = CourseDetailUiState.Error(
                        error.message ?: "读取课程失败",
                    )
                }
                .collect { state -> _uiState.value = state }
        }
    }

    fun onEditClicked() {
        viewModelScope.launch { _events.send(CourseDetailEvent.EditRequested) }
    }

    fun onDeleteClicked() {
        viewModelScope.launch { _events.send(CourseDetailEvent.DeleteConfirmationRequested) }
    }

    fun confirmDelete() {
        viewModelScope.launch {
            if (repository.deleteCourse(courseId)) {
                _events.send(CourseDetailEvent.Deleted)
            } else {
                _events.send(CourseDetailEvent.DeleteTargetMissing)
            }
        }
    }
}

class CourseDetailViewModelFactory(
    private val courseId: String,
    private val repository: CourseDetailRepository,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CourseDetailViewModel::class.java)) {
            return CourseDetailViewModel(courseId, repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
    }
}
