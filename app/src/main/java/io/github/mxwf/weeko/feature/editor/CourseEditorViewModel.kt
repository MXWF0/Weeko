package io.github.mxwf.weeko.feature.editor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import io.github.mxwf.weeko.data.CourseEditorRepository
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch

sealed interface CourseEditorEvent {
    data object Saved : CourseEditorEvent
    data object CancelRequested : CourseEditorEvent
}

class CourseEditorViewModel(
    private val courseId: String,
    private val repository: CourseEditorRepository,
) : ViewModel() {
    private val _uiState = MutableStateFlow<CourseEditorUiState>(CourseEditorUiState.Loading)
    val uiState: StateFlow<CourseEditorUiState> = _uiState.asStateFlow()

    private val _events = Channel<CourseEditorEvent>(capacity = Channel.BUFFERED)
    val events = _events.receiveAsFlow()

    init {
        viewModelScope.launch {
            repository.observeCourseDetail(courseId)
                .map { record ->
                    record?.let { CourseEditorUiState.Content(it.toEditorForm()) }
                        ?: CourseEditorUiState.NotFound
                }
                .catch { error ->
                    _uiState.value = CourseEditorUiState.Error(
                        error.message ?: "读取课程失败",
                    )
                }
                .collect { state -> _uiState.value = state }
        }
    }

    fun onNameChanged(value: String) = updateForm { copy(name = value) }

    fun onCourseCodeChanged(value: String) = updateForm { copy(courseCode = value) }

    fun onCreditChanged(value: String) = updateForm { copy(credit = value) }

    fun onNoteChanged(value: String) = updateForm { copy(note = value) }

    fun onColorSelected(seed: Long) = updateForm { copy(colorSeed = seed) }

    fun onSessionChanged(index: Int, session: CourseEditorSessionForm) =
        updateForm {
            copy(sessions = sessions.toMutableList().also { it[index] = session })
        }

    fun addSession() = updateForm {
        copy(sessions = sessions + defaultEditorSession(weekCount))
    }

    fun removeSession(index: Int) = updateForm {
        copy(sessions = sessions.toMutableList().also { it.removeAt(index) })
    }

    fun onCancelClicked() {
        viewModelScope.launch { _events.send(CourseEditorEvent.CancelRequested) }
    }

    fun onSaveClicked() {
        val state = _uiState.value as? CourseEditorUiState.Content ?: return
        val form = state.form
        val validationError = form.validationError()
        if (validationError != null) {
            _uiState.value = state.copy(errorMessage = validationError)
            return
        }

        _uiState.value = state.copy(isSaving = true, errorMessage = null)
        viewModelScope.launch {
            try {
                val saveData = form.toSaveData()
                if (repository.saveCourse(saveData.course, saveData.sessions)) {
                    _events.send(CourseEditorEvent.Saved)
                } else {
                    _uiState.value = state.copy(
                        isSaving = false,
                        errorMessage = "课程不存在，无法保存",
                    )
                }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                _uiState.value = state.copy(
                    isSaving = false,
                    errorMessage = error.message ?: "保存课程失败",
                )
            }
        }
    }

    private fun updateForm(transform: CourseEditorForm.() -> CourseEditorForm) {
        val state = _uiState.value as? CourseEditorUiState.Content ?: return
        _uiState.value = state.copy(
            form = state.form.transform(),
            errorMessage = null,
        )
    }
}

class CourseEditorViewModelFactory(
    private val courseId: String,
    private val repository: CourseEditorRepository,
) : ViewModelProvider.Factory {
    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CourseEditorViewModel::class.java)) {
            return CourseEditorViewModel(courseId, repository) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
    }
}
