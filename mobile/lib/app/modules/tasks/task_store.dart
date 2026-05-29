import 'package:mobx/mobx.dart';

import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/services/notification_service.dart';
import 'task_model.dart';
import 'task_repository.dart';

class TaskStore {
  TaskStore(this._repository, this._notificationService);

  final TaskRepository _repository;
  final NotificationService _notificationService;

  final tasks = ObservableList<TaskModel>();
  final isLoading = Observable(false);
  final isSaving = Observable(false);
  final error = Observable<String?>(null);

  late final Action _loadTasksAction = Action(_loadTasks);
  late final Action _createTaskAction = Action(_createTask);
  late final Action _updateTaskAction = Action(_updateTask);
  late final Action _updateStatusAction = Action(_updateStatus);
  late final Action _deleteTaskAction = Action(_deleteTask);

  Future<void> loadTasks(int projectId) {
    return _loadTasksAction([projectId]) as Future<void>;
  }

  Future<bool> createTask({
    required int projectId,
    required String title,
    required String description,
    required TaskPriority priority,
  }) {
    return _createTaskAction(const [], {
      'projectId': projectId,
      'title': title,
      'description': description,
      'priority': priority,
    }) as Future<bool>;
  }

  Future<bool> updateTask({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
  }) {
    return _updateTaskAction(const [], {
      'projectId': projectId,
      'task': task,
      'title': title,
      'description': description,
      'priority': priority,
    }) as Future<bool>;
  }

  Future<void> updateStatus(int projectId, TaskModel task, TaskStatus status) {
    return _updateStatusAction([projectId, task, status]) as Future<void>;
  }

  Future<void> deleteTask(int projectId, TaskModel task) {
    return _deleteTaskAction([projectId, task]) as Future<void>;
  }

  Future<void> _loadTasks(int projectId) async {
    isLoading.value = true;
    error.value = null;

    try {
      final response = await _repository.list(projectId);
      tasks
        ..clear()
        ..addAll(response);
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.load.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId},
      );
      error.value = errorMessageFor(exception,
          fallback: 'Não foi possível carregar as tarefas.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _createTask({
    required int projectId,
    required String title,
    required String description,
    required TaskPriority priority,
  }) async {
    isSaving.value = true;
    error.value = null;

    try {
      final task = await _repository.create(
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
      );
      tasks.insert(0, task);
      await _notificationService.show('Tarefa criada', task.title);
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.create.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId},
      );
      error.value = errorMessageFor(exception,
          fallback: 'Não foi possível criar a tarefa.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _updateStatus(
      int projectId, TaskModel task, TaskStatus status) async {
    try {
      final updatedTask = await _repository.updateStatus(
        projectId: projectId,
        task: task,
        status: status,
      );
      final index = tasks.indexWhere((item) => item.id == updatedTask.id);
      if (index >= 0) {
        // Atualiza o estado local após sucesso da API para manter a UI responsiva.
        tasks[index] = updatedTask;
      }
      await _notificationService.show(
          'Status atualizado', updatedTask.status.label);
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.status.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {
          'projectId': projectId,
          'taskId': task.id,
          'status': status.value
        },
      );
      error.value = errorMessageFor(exception,
          fallback: 'Não foi possível atualizar o status.');
    }
  }

  Future<bool> _updateTask({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
  }) async {
    isSaving.value = true;
    error.value = null;

    try {
      final updatedTask = await _repository.update(
        projectId: projectId,
        task: task,
        title: title,
        description: description,
        priority: priority,
      );
      final index = tasks.indexWhere((item) => item.id == updatedTask.id);
      if (index >= 0) {
        tasks[index] = updatedTask;
      }
      await _notificationService.show('Tarefa editada', updatedTask.title);
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.update.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id},
      );
      error.value = errorMessageFor(exception,
          fallback: 'Não foi possível editar a tarefa.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _deleteTask(int projectId, TaskModel task) async {
    try {
      await _repository.delete(projectId, task.id);
      tasks.removeWhere((item) => item.id == task.id);
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.delete.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id},
      );
      error.value = errorMessageFor(exception,
          fallback: 'Não foi possível excluir a tarefa.');
    }
  }
}
