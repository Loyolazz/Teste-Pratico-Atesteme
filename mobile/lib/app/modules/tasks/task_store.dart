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
  final loadingPhase = Observable<String?>(null);
  final savingPhase = Observable<String?>(null);

  Future<void> loadTasks(int projectId) {
    return _loadTasks(projectId);
  }

  Future<bool> createTask({
    required int projectId,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
  }) {
    return _createTask(
      projectId: projectId,
      title: title,
      description: description,
      priority: priority,
      status: status,
    );
  }

  Future<bool> updateTask({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
  }) {
    return _updateTask(
      projectId: projectId,
      task: task,
      title: title,
      description: description,
      priority: priority,
      status: status,
    );
  }

  Future<void> updateStatus(int projectId, TaskModel task, TaskStatus status) {
    return _updateStatus(projectId, task, status);
  }

  Future<void> deleteTask(int projectId, TaskModel task) {
    return _deleteTask(projectId, task);
  }

  void _setLoadingPhase(String? message,
      {Map<String, Object?> context = const {}}) {
    runInAction(() => loadingPhase.value = message);
    if (message != null) {
      AppLogger.info('task_store.loading_phase',
          context: {'phase': message, ...context});
    }
  }

  void _setSavingPhase(String? message,
      {Map<String, Object?> context = const {}}) {
    runInAction(() => savingPhase.value = message);
    if (message != null) {
      AppLogger.info('task_store.saving_phase',
          context: {'phase': message, ...context});
    }
  }

  Future<void> _loadTasks(int projectId) async {
    AppLogger.info('task_store.load.started',
        context: {'projectId': projectId});
    runInAction(() {
      isLoading.value = true;
      error.value = null;
    });
    _setLoadingPhase('Preparando carregamento das tarefas...',
        context: {'projectId': projectId});

    try {
      _setLoadingPhase('Sincronizando fila offline e buscando tarefas...',
          context: {'projectId': projectId});
      final response = await _repository.list(projectId);
      _setLoadingPhase('Atualizando lista de tarefas...',
          context: {'projectId': projectId, 'items': response.length});
      runInAction(() {
        tasks
          ..clear()
          ..addAll(response);
      });
      AppLogger.info('task_store.load.completed',
          context: {'projectId': projectId, 'items': response.length});
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.load.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId},
      );
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível carregar as tarefas.');
      });
    } finally {
      runInAction(() {
        isLoading.value = false;
        loadingPhase.value = null;
      });
    }
  }

  Future<bool> _createTask({
    required int projectId,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
  }) async {
    AppLogger.info('task_store.create.started',
        context: {'projectId': projectId, 'title': title});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Enviando tarefa para a API...',
        context: {'projectId': projectId});

    try {
      final task = await _repository.create(
        projectId: projectId,
        title: title,
        description: description,
        priority: priority,
        status: status,
      );
      _setSavingPhase('Atualizando tela com a tarefa...',
          context: {'projectId': projectId, 'taskId': task.id});
      runInAction(() => tasks.insert(0, task));
      _setSavingPhase('Mostrando notificação...',
          context: {'projectId': projectId, 'taskId': task.id});
      await _notificationService.show('Tarefa criada', task.title);
      AppLogger.info('task_store.create.completed',
          context: {'projectId': projectId, 'taskId': task.id});
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.create.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId},
      );
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível criar a tarefa.');
      });
      return false;
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }

  Future<void> _updateStatus(
      int projectId, TaskModel task, TaskStatus status) async {
    AppLogger.info('task_store.status.started', context: {
      'projectId': projectId,
      'taskId': task.id,
      'status': status.value
    });
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Atualizando status da tarefa...',
        context: {'projectId': projectId, 'taskId': task.id});

    try {
      final updatedTask = await _repository.updateStatus(
        projectId: projectId,
        task: task,
        status: status,
      );
      _setSavingPhase('Aplicando novo status na tela...',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      final index = tasks.indexWhere((item) => item.id == updatedTask.id);
      if (index >= 0) {
        runInAction(() => tasks[index] = updatedTask);
      }
      _setSavingPhase('Mostrando notificação...',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _notificationService.show(
          'Status atualizado', updatedTask.status.label);
      AppLogger.info('task_store.status.completed', context: {
        'projectId': projectId,
        'taskId': updatedTask.id,
        'status': updatedTask.status.value
      });
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
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível atualizar o status.');
      });
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }

  Future<bool> _updateTask({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
  }) async {
    AppLogger.info('task_store.update.started',
        context: {'projectId': projectId, 'taskId': task.id, 'title': title});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Enviando alterações da tarefa...',
        context: {'projectId': projectId, 'taskId': task.id});

    try {
      final updatedTask = await _repository.update(
        projectId: projectId,
        task: task,
        title: title,
        description: description,
        priority: priority,
        status: status,
      );
      _setSavingPhase('Aplicando alterações na tela...',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      final index = tasks.indexWhere((item) => item.id == updatedTask.id);
      if (index >= 0) {
        runInAction(() => tasks[index] = updatedTask);
      }
      _setSavingPhase('Mostrando notificação...',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _notificationService.show('Tarefa editada', updatedTask.title);
      AppLogger.info('task_store.update.completed',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.update.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id},
      );
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível editar a tarefa.');
      });
      return false;
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }

  Future<void> _deleteTask(int projectId, TaskModel task) async {
    AppLogger.info('task_store.delete.started',
        context: {'projectId': projectId, 'taskId': task.id});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Excluindo tarefa...',
        context: {'projectId': projectId, 'taskId': task.id});
    try {
      await _repository.delete(projectId, task.id);
      _setSavingPhase('Removendo tarefa da lista...',
          context: {'projectId': projectId, 'taskId': task.id});
      runInAction(() => tasks.removeWhere((item) => item.id == task.id));
      AppLogger.info('task_store.delete.completed',
          context: {'projectId': projectId, 'taskId': task.id});
    } catch (exception, stackTrace) {
      AppLogger.error(
        'task_store.delete.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id},
      );
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível excluir a tarefa.');
      });
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }
}
