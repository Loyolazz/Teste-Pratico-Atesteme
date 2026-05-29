import '../../shared/services/api_client.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/services/offline_sync_service.dart';
import '../../shared/storage/local_database.dart';
import 'task_model.dart';

class TaskRepository {
  const TaskRepository(this._apiClient, this._localDatabase, this._offlineSyncService);

  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final OfflineSyncService _offlineSyncService;

  Future<List<TaskModel>> list(int projectId) async {
    try {
      await _offlineSyncService.syncPendingOperations();
      final data = await _apiClient.get<List<dynamic>>('/projects/$projectId/tasks');
      final tasks = data
          .cast<Map<String, dynamic>>()
          .map(TaskModel.fromJson)
          .toList();
      await _localDatabase.saveTasks(projectId, tasks);
      return tasks;
    } catch (error, stackTrace) {
      final cachedTasks = await _localDatabase.getTasks(projectId);
      if (isOfflineError(error) && cachedTasks.isNotEmpty) {
        AppLogger.warning(
          'task.list.cache_fallback',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'cachedItems': cachedTasks.length},
        );
        return cachedTasks;
      }

      AppLogger.error(
        'task.list.failed',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': projectId},
      );
      rethrow;
    }
  }

  Future<TaskModel> create({
    required int projectId,
    required String title,
    required String description,
    required TaskPriority priority,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': TaskStatus.pendente.value,
    };

    try {
      final data = await _apiClient.post<Map<String, dynamic>>('/projects/$projectId/tasks', payload);
      final task = TaskModel.fromJson(data);
      await _localDatabase.upsertTask(task);
      return task;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.create.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'taskTitle': title},
        );
        rethrow;
      }

      AppLogger.warning(
        'task.create.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskTitle': title},
      );
      final task = TaskModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        title: title,
        description: description,
        priority: priority,
        status: TaskStatus.pendente,
        createdAt: DateTime.now(),
        projectId: projectId,
      );
      await _localDatabase.upsertTask(task);
      await _localDatabase.addPendingOperation(
        operationType: 'CREATE_TASK',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      return task;
    }
  }

  Future<TaskModel> update({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': task.status.value,
    };

    try {
      final data = await _apiClient.put<Map<String, dynamic>>('/projects/$projectId/tasks/${task.id}', payload);
      final updatedTask = TaskModel.fromJson(data);
      await _localDatabase.upsertTask(updatedTask);
      return updatedTask;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.update.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'taskId': task.id, 'taskTitle': title},
        );
        rethrow;
      }

      AppLogger.warning(
        'task.update.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id, 'taskTitle': title},
      );
      final updatedTask = TaskModel(
        id: task.id,
        title: title,
        description: description,
        priority: priority,
        status: task.status,
        createdAt: task.createdAt,
        projectId: task.projectId,
      );
      await _localDatabase.upsertTask(updatedTask);
      if (task.id < 0) {
        await _localDatabase.deletePendingOperationsForResource(task.id);
        await _localDatabase.addPendingOperation(
          operationType: 'CREATE_TASK',
          payload: payload,
          projectId: projectId,
          resourceId: task.id,
        );
        return updatedTask;
      }

      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_TASK',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      return updatedTask;
    }
  }

  Future<TaskModel> updateStatus({
    required int projectId,
    required TaskModel task,
    required TaskStatus status,
  }) async {
    final payload = {'status': status.value};

    try {
      final data = await _apiClient.patch<Map<String, dynamic>>(
        '/projects/$projectId/tasks/${task.id}/status',
        payload,
      );
      final updatedTask = TaskModel.fromJson(data);
      await _localDatabase.upsertTask(updatedTask);
      return updatedTask;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.status.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'taskId': task.id, 'status': status.value},
        );
        rethrow;
      }

      AppLogger.warning(
        'task.status.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': task.id, 'status': status.value},
      );
      final updatedTask = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        priority: task.priority,
        status: status,
        createdAt: task.createdAt,
        projectId: task.projectId,
      );
      await _localDatabase.upsertTask(updatedTask);
      if (task.id < 0) {
        await _localDatabase.deletePendingOperationsForResource(task.id);
        await _localDatabase.addPendingOperation(
          operationType: 'CREATE_TASK',
          payload: {
            'title': updatedTask.title,
            'description': updatedTask.description ?? '',
            'priority': updatedTask.priority.value,
            'status': updatedTask.status.value,
          },
          projectId: projectId,
          resourceId: task.id,
        );
        return updatedTask;
      }

      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_TASK_STATUS',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      return updatedTask;
    }
  }

  Future<void> delete(int projectId, int taskId) async {
    try {
      await _apiClient.deleteVoid('/projects/$projectId/tasks/$taskId');
      await _localDatabase.deleteTask(taskId);
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.delete.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId, 'taskId': taskId},
        );
        rethrow;
      }

      AppLogger.warning(
        'task.delete.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': projectId, 'taskId': taskId},
      );
      await _localDatabase.deleteTask(taskId);
      if (taskId < 0) {
        await _localDatabase.deletePendingOperationsForResource(taskId);
        return;
      }
      await _localDatabase.addPendingOperation(
        operationType: 'DELETE_TASK',
        payload: null,
        projectId: projectId,
        resourceId: taskId,
      );
    }
  }
}
