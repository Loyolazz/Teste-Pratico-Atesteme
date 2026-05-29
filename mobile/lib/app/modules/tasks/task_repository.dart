import '../../shared/services/api_client.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/services/offline_sync_service.dart';
import '../../shared/storage/local_database.dart';
import 'task_model.dart';

class TaskRepository {
  const TaskRepository(
      this._apiClient, this._localDatabase, this._offlineSyncService);

  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final OfflineSyncService _offlineSyncService;

  Future<List<TaskModel>> list(int projectId) async {
    try {
      AppLogger.info('task.repository.list.started',
          context: {'projectId': projectId});
      AppLogger.info('task.repository.list.sync_pending.started',
          context: {'projectId': projectId});
      await _offlineSyncService.syncPendingOperations();
      AppLogger.info('task.repository.list.api.started',
          context: {'projectId': projectId});
      final data =
          await _apiClient.get<List<dynamic>>('/projects/$projectId/tasks');
      final tasks =
          data.cast<Map<String, dynamic>>().map(TaskModel.fromJson).toList();
      AppLogger.info('task.repository.list.cache_save.started',
          context: {'projectId': projectId, 'items': tasks.length});
      await _localDatabase.saveTasks(projectId, tasks);
      AppLogger.info('task.repository.list.completed',
          context: {'projectId': projectId, 'items': tasks.length});
      return tasks;
    } catch (error, stackTrace) {
      AppLogger.warning('task.repository.list.trying_cache',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': projectId});
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
    required TaskStatus status,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
    };

    try {
      AppLogger.info('task.repository.create.api.started',
          context: {'projectId': projectId, 'title': title});
      final data = await _apiClient.post<Map<String, dynamic>>(
          '/projects/$projectId/tasks', payload);
      final task = TaskModel.fromJson(data);
      AppLogger.info('task.repository.create.cache_save.started',
          context: {'projectId': projectId, 'taskId': task.id});
      await _localDatabase.upsertTask(task);
      AppLogger.info('task.repository.create.completed',
          context: {'projectId': projectId, 'taskId': task.id});
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
        status: status,
        createdAt: DateTime.now(),
        projectId: projectId,
      );
      AppLogger.info('task.repository.create.offline_cache_save.started',
          context: {'projectId': projectId, 'taskId': task.id});
      await _localDatabase.upsertTask(task);
      AppLogger.info('task.repository.create.queue_add.started',
          context: {'projectId': projectId, 'taskId': task.id});
      await _localDatabase.addPendingOperation(
        operationType: 'CREATE_TASK',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      AppLogger.info('task.repository.create.offline_completed',
          context: {'projectId': projectId, 'taskId': task.id});
      return task;
    }
  }

  Future<TaskModel> update({
    required int projectId,
    required TaskModel task,
    required String title,
    required String description,
    required TaskPriority priority,
    required TaskStatus status,
  }) async {
    final payload = {
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
    };

    try {
      AppLogger.info('task.repository.update.api.started',
          context: {'projectId': projectId, 'taskId': task.id});
      final data = await _apiClient.put<Map<String, dynamic>>(
          '/projects/$projectId/tasks/${task.id}', payload);
      final updatedTask = TaskModel.fromJson(data);
      AppLogger.info('task.repository.update.cache_save.started',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _localDatabase.upsertTask(updatedTask);
      AppLogger.info('task.repository.update.completed',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      return updatedTask;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.update.failed',
          error: error,
          stackTrace: stackTrace,
          context: {
            'projectId': projectId,
            'taskId': task.id,
            'taskTitle': title
          },
        );
        rethrow;
      }

      AppLogger.warning(
        'task.update.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {
          'projectId': projectId,
          'taskId': task.id,
          'taskTitle': title
        },
      );
      final updatedTask = TaskModel(
        id: task.id,
        title: title,
        description: description,
        priority: priority,
        status: status,
        createdAt: task.createdAt,
        projectId: task.projectId,
      );
      AppLogger.info('task.repository.update.offline_cache_save.started',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _localDatabase.upsertTask(updatedTask);
      if (task.id < 0) {
        AppLogger.info('task.repository.update.pending_create_replace.started',
            context: {'projectId': projectId, 'taskId': task.id});
        await _localDatabase.deletePendingOperationsForResource(task.id);
        await _localDatabase.addPendingOperation(
          operationType: 'CREATE_TASK',
          payload: payload,
          projectId: projectId,
          resourceId: task.id,
        );
        AppLogger.info('task.repository.update.offline_completed',
            context: {'projectId': projectId, 'taskId': task.id});
        return updatedTask;
      }

      AppLogger.info('task.repository.update.queue_add.started',
          context: {'projectId': projectId, 'taskId': task.id});
      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_TASK',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      AppLogger.info('task.repository.update.offline_completed',
          context: {'projectId': projectId, 'taskId': task.id});
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
      AppLogger.info('task.repository.status.api.started',
          context: {'projectId': projectId, 'taskId': task.id});
      final data = await _apiClient.patch<Map<String, dynamic>>(
        '/projects/$projectId/tasks/${task.id}/status',
        payload,
      );
      final updatedTask = TaskModel.fromJson(data);
      AppLogger.info('task.repository.status.cache_save.started',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _localDatabase.upsertTask(updatedTask);
      AppLogger.info('task.repository.status.completed',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      return updatedTask;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'task.status.failed',
          error: error,
          stackTrace: stackTrace,
          context: {
            'projectId': projectId,
            'taskId': task.id,
            'status': status.value
          },
        );
        rethrow;
      }

      AppLogger.warning(
        'task.status.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {
          'projectId': projectId,
          'taskId': task.id,
          'status': status.value
        },
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
      AppLogger.info('task.repository.status.offline_cache_save.started',
          context: {'projectId': projectId, 'taskId': updatedTask.id});
      await _localDatabase.upsertTask(updatedTask);
      if (task.id < 0) {
        AppLogger.info('task.repository.status.pending_create_replace.started',
            context: {'projectId': projectId, 'taskId': task.id});
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
        AppLogger.info('task.repository.status.offline_completed',
            context: {'projectId': projectId, 'taskId': task.id});
        return updatedTask;
      }

      AppLogger.info('task.repository.status.queue_add.started',
          context: {'projectId': projectId, 'taskId': task.id});
      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_TASK_STATUS',
        payload: payload,
        projectId: projectId,
        resourceId: task.id,
      );
      AppLogger.info('task.repository.status.offline_completed',
          context: {'projectId': projectId, 'taskId': task.id});
      return updatedTask;
    }
  }

  Future<void> delete(int projectId, int taskId) async {
    try {
      AppLogger.info('task.repository.delete.api.started',
          context: {'projectId': projectId, 'taskId': taskId});
      await _apiClient.deleteVoid('/projects/$projectId/tasks/$taskId');
      AppLogger.info('task.repository.delete.cache_delete.started',
          context: {'projectId': projectId, 'taskId': taskId});
      await _localDatabase.deleteTask(taskId);
      AppLogger.info('task.repository.delete.completed',
          context: {'projectId': projectId, 'taskId': taskId});
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
      AppLogger.info('task.repository.delete.offline_cache_delete.started',
          context: {'projectId': projectId, 'taskId': taskId});
      await _localDatabase.deleteTask(taskId);
      if (taskId < 0) {
        AppLogger.info('task.repository.delete.pending_local_cleanup.started',
            context: {'projectId': projectId, 'taskId': taskId});
        await _localDatabase.deletePendingOperationsForResource(taskId);
        AppLogger.info('task.repository.delete.offline_completed',
            context: {'projectId': projectId, 'taskId': taskId});
        return;
      }
      AppLogger.info('task.repository.delete.queue_add.started',
          context: {'projectId': projectId, 'taskId': taskId});
      await _localDatabase.addPendingOperation(
        operationType: 'DELETE_TASK',
        payload: null,
        projectId: projectId,
        resourceId: taskId,
      );
      AppLogger.info('task.repository.delete.offline_completed',
          context: {'projectId': projectId, 'taskId': taskId});
    }
  }
}
