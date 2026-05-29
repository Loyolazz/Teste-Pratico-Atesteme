import '../storage/local_database.dart';
import 'app_error.dart';
import 'app_logger.dart';
import 'api_client.dart';
import '../../modules/projects/project_model.dart';
import '../../modules/tasks/task_model.dart';

class OfflineSyncService {
  const OfflineSyncService(this._apiClient, this._localDatabase);

  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;

  Future<void> syncPendingOperations() async {
    var operations = await _localDatabase.getPendingOperations();
    if (operations.isNotEmpty) {
      AppLogger.info('offline_sync.started',
          context: {'pendingOperations': operations.length});
    }

    while (operations.isNotEmpty) {
      final operation = operations.first;
      bool synced;
      AppLogger.info(
        'offline_sync.operation.started',
        context: {
          'operationId': operation['id'],
          'operationType': operation['operation_type'],
          'resourceId': operation['resource_id'],
          'projectId': operation['project_id'],
        },
      );

      try {
        synced = await _syncOperation(operation);
      } catch (error, stackTrace) {
        synced = await _resolveSyncError(operation, error, stackTrace);
      }

      if (!synced) {
        AppLogger.warning(
          'offline_sync.paused',
          context: {
            'operationId': operation['id'],
            'operationType': operation['operation_type'],
            'resourceId': operation['resource_id'],
            'projectId': operation['project_id'],
          },
        );
        break;
      }

      AppLogger.info(
        'offline_sync.operation.delete_local.started',
        context: {'operationId': operation['id']},
      );
      await _localDatabase.deletePendingOperation(operation['id'] as int);
      operations = await _localDatabase.getPendingOperations();
      AppLogger.info(
        'offline_sync.operation.completed',
        context: {
          'operationId': operation['id'],
          'remainingOperations': operations.length,
        },
      );
    }

    if (operations.isEmpty) {
      AppLogger.info('offline_sync.finished');
    }
  }

  Future<bool> _syncOperation(Map<String, Object?> operation) async {
    final type = operation['operation_type'] as String;
    final resourceId = operation['resource_id'] as int?;
    final projectId = operation['project_id'] as int?;
    final payload = decodeOperationPayload(operation['payload']);

    switch (type) {
      case 'CREATE_PROJECT':
        AppLogger.info('offline_sync.api.create_project.started',
            context: {'operationId': operation['id']});
        final data =
            await _apiClient.post<Map<String, dynamic>>('/projects', payload!);
        final project = ProjectModel.fromJson(data);
        if (resourceId != null && resourceId < 0) {
          AppLogger.info('offline_sync.project_reference_replace.started',
              context: {
                'operationId': operation['id'],
                'fromProjectId': resourceId,
                'toProjectId': project.id,
              });
          await _localDatabase.replaceProjectReferences(
            fromProjectId: resourceId,
            toProjectId: project.id,
          );
          await _localDatabase.deleteProject(resourceId);
        }
        await _localDatabase.upsertProject(project);
        return true;
      case 'UPDATE_PROJECT':
        AppLogger.info('offline_sync.api.update_project.started',
            context: {'operationId': operation['id'], 'projectId': resourceId});
        await _apiClient.put<Map<String, dynamic>>(
            '/projects/$resourceId', payload!);
        return true;
      case 'DELETE_PROJECT':
        if (resourceId != null && resourceId > 0) {
          AppLogger.info('offline_sync.api.delete_project.started', context: {
            'operationId': operation['id'],
            'projectId': resourceId
          });
          await _apiClient.deleteVoid('/projects/$resourceId');
        }
        return true;
      case 'CREATE_TASK':
        AppLogger.info('offline_sync.api.create_task.started', context: {
          'operationId': operation['id'],
          'projectId': projectId,
          'taskId': resourceId
        });
        final data = await _apiClient.post<Map<String, dynamic>>(
            '/projects/$projectId/tasks', payload!);
        final task = TaskModel.fromJson(data);
        if (resourceId != null && resourceId < 0) {
          await _localDatabase.deleteTask(resourceId);
        }
        await _localDatabase.upsertTask(task);
        return true;
      case 'UPDATE_TASK':
        AppLogger.info('offline_sync.api.update_task.started', context: {
          'operationId': operation['id'],
          'projectId': projectId,
          'taskId': resourceId
        });
        await _apiClient.put<Map<String, dynamic>>(
            '/projects/$projectId/tasks/$resourceId', payload!);
        return true;
      case 'UPDATE_TASK_STATUS':
        AppLogger.info('offline_sync.api.update_task_status.started', context: {
          'operationId': operation['id'],
          'projectId': projectId,
          'taskId': resourceId
        });
        await _apiClient.patch<Map<String, dynamic>>(
            '/projects/$projectId/tasks/$resourceId/status', payload!);
        return true;
      case 'DELETE_TASK':
        if (resourceId != null && resourceId > 0) {
          AppLogger.info('offline_sync.api.delete_task.started', context: {
            'operationId': operation['id'],
            'projectId': projectId,
            'taskId': resourceId
          });
          await _apiClient.deleteVoid('/projects/$projectId/tasks/$resourceId');
        }
        return true;
      default:
        AppLogger.warning('offline_sync.operation.unknown_type_ignored',
            context: {
              'operationId': operation['id'],
              'operationType': type,
            });
        return true;
    }
  }

  Future<bool> _resolveSyncError(
    Map<String, Object?> operation,
    Object error,
    StackTrace stackTrace,
  ) async {
    final statusCode = error is AppException ? error.statusCode : null;
    if (statusCode != 404) {
      AppLogger.error(
        'offline_sync.operation_failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'operationId': operation['id'],
          'operationType': operation['operation_type'],
          'resourceId': operation['resource_id'],
          'projectId': operation['project_id'],
        },
      );
      return false;
    }

    final type = operation['operation_type'] as String;
    final resourceId = operation['resource_id'] as int?;

    AppLogger.warning(
      'offline_sync.conflict_resolved_not_found',
      error: error,
      stackTrace: stackTrace,
      context: {
        'operationId': operation['id'],
        'operationType': type,
        'resourceId': resourceId,
        'projectId': operation['project_id'],
      },
    );

    switch (type) {
      case 'UPDATE_PROJECT':
      case 'DELETE_PROJECT':
        if (resourceId != null) {
          await _localDatabase.deleteProject(resourceId);
        }
        return true;
      case 'CREATE_TASK':
      case 'UPDATE_TASK':
      case 'UPDATE_TASK_STATUS':
      case 'DELETE_TASK':
        if (resourceId != null) {
          await _localDatabase.deleteTask(resourceId);
        }
        return true;
      default:
        return false;
    }
  }
}
