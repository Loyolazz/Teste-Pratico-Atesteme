import '../../shared/services/api_client.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/services/offline_sync_service.dart';
import '../../shared/storage/local_database.dart';
import 'project_model.dart';

class ProjectRepository {
  const ProjectRepository(
      this._apiClient, this._localDatabase, this._offlineSyncService);

  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final OfflineSyncService _offlineSyncService;

  Future<List<ProjectModel>> list() async {
    try {
      AppLogger.info('project.repository.list.started');
      AppLogger.info('project.repository.list.sync_pending.started');
      await _offlineSyncService.syncPendingOperations();
      AppLogger.info('project.repository.list.api.started');
      final data = await _apiClient.get<List<dynamic>>('/projects');
      final projects =
          data.cast<Map<String, dynamic>>().map(ProjectModel.fromJson).toList();
      AppLogger.info('project.repository.list.cache_save.started',
          context: {'items': projects.length});
      await _localDatabase.saveProjects(projects);
      AppLogger.info('project.repository.list.completed',
          context: {'items': projects.length});
      return projects;
    } catch (error, stackTrace) {
      AppLogger.warning('project.repository.list.trying_cache',
          error: error, stackTrace: stackTrace);
      final cachedProjects = await _localDatabase.getProjects();
      if (isOfflineError(error) && cachedProjects.isNotEmpty) {
        AppLogger.warning(
          'project.list.cache_fallback',
          error: error,
          stackTrace: stackTrace,
          context: {'cachedItems': cachedProjects.length},
        );
        return cachedProjects;
      }

      AppLogger.error('project.list.failed',
          error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProjectModel> create({
    required String name,
    required String description,
    required List<String> workers,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'workers': workers,
    };

    try {
      AppLogger.info('project.repository.create.api.started',
          context: {'projectName': name});
      final data =
          await _apiClient.post<Map<String, dynamic>>('/projects', payload);
      final project = ProjectModel.fromJson(data);
      AppLogger.info('project.repository.create.cache_save.started',
          context: {'projectId': project.id});
      await _localDatabase.upsertProject(project);
      AppLogger.info('project.repository.create.completed',
          context: {'projectId': project.id});
      return project;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'project.create.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectName': name},
        );
        rethrow;
      }

      AppLogger.warning(
        'project.create.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectName': name},
      );
      final project = ProjectModel(
        id: -DateTime.now().millisecondsSinceEpoch,
        name: name,
        description: description,
        workers: workers,
        createdAt: DateTime.now(),
        taskCount: 0,
      );
      AppLogger.info('project.repository.create.offline_cache_save.started',
          context: {'projectId': project.id});
      await _localDatabase.upsertProject(project);
      AppLogger.info('project.repository.create.queue_add.started',
          context: {'projectId': project.id});
      await _localDatabase.addPendingOperation(
        operationType: 'CREATE_PROJECT',
        payload: payload,
        resourceId: project.id,
      );
      AppLogger.info('project.repository.create.offline_completed',
          context: {'projectId': project.id});
      return project;
    }
  }

  Future<ProjectModel> update({
    required ProjectModel project,
    required String name,
    required String description,
    required List<String> workers,
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'workers': workers,
    };

    try {
      AppLogger.info('project.repository.update.api.started',
          context: {'projectId': project.id});
      final data = await _apiClient.put<Map<String, dynamic>>(
          '/projects/${project.id}', payload);
      final updatedProject = ProjectModel.fromJson(data);
      AppLogger.info('project.repository.update.cache_save.started',
          context: {'projectId': updatedProject.id});
      await _localDatabase.upsertProject(updatedProject);
      AppLogger.info('project.repository.update.completed',
          context: {'projectId': updatedProject.id});
      return updatedProject;
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'project.update.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': project.id, 'projectName': name},
        );
        rethrow;
      }

      AppLogger.warning(
        'project.update.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': project.id, 'projectName': name},
      );
      final updatedProject = ProjectModel(
        id: project.id,
        name: name,
        description: description,
        workers: workers,
        createdAt: project.createdAt,
        taskCount: project.taskCount,
      );
      AppLogger.info('project.repository.update.offline_cache_save.started',
          context: {'projectId': updatedProject.id});
      await _localDatabase.upsertProject(updatedProject);
      if (project.id < 0) {
        AppLogger.info(
            'project.repository.update.pending_create_replace.started',
            context: {'projectId': project.id});
        await _localDatabase.deletePendingOperationsForResource(project.id);
        await _localDatabase.addPendingOperation(
          operationType: 'CREATE_PROJECT',
          payload: payload,
          resourceId: project.id,
        );
        AppLogger.info('project.repository.update.offline_completed',
            context: {'projectId': project.id});
        return updatedProject;
      }

      AppLogger.info('project.repository.update.queue_add.started',
          context: {'projectId': project.id});
      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_PROJECT',
        payload: payload,
        resourceId: project.id,
      );
      AppLogger.info('project.repository.update.offline_completed',
          context: {'projectId': project.id});
      return updatedProject;
    }
  }

  Future<void> delete(ProjectModel project) async {
    try {
      AppLogger.info('project.repository.delete.api.started',
          context: {'projectId': project.id});
      await _apiClient.deleteVoid('/projects/${project.id}');
      AppLogger.info('project.repository.delete.cache_delete.started',
          context: {'projectId': project.id});
      await _localDatabase.deleteProject(project.id);
      AppLogger.info('project.repository.delete.completed',
          context: {'projectId': project.id});
    } catch (error, stackTrace) {
      if (!isOfflineError(error)) {
        AppLogger.error(
          'project.delete.failed',
          error: error,
          stackTrace: stackTrace,
          context: {'projectId': project.id},
        );
        rethrow;
      }

      AppLogger.warning(
        'project.delete.offline_queued',
        error: error,
        stackTrace: stackTrace,
        context: {'projectId': project.id},
      );
      AppLogger.info('project.repository.delete.offline_cache_delete.started',
          context: {'projectId': project.id});
      await _localDatabase.deleteProject(project.id);
      if (project.id < 0) {
        AppLogger.info(
            'project.repository.delete.pending_local_cleanup.started',
            context: {'projectId': project.id});
        await _localDatabase.deletePendingOperationsForProject(project.id);
        AppLogger.info('project.repository.delete.offline_completed',
            context: {'projectId': project.id});
        return;
      }

      AppLogger.info('project.repository.delete.queue_add.started',
          context: {'projectId': project.id});
      await _localDatabase.addPendingOperation(
        operationType: 'DELETE_PROJECT',
        payload: null,
        resourceId: project.id,
      );
      AppLogger.info('project.repository.delete.offline_completed',
          context: {'projectId': project.id});
    }
  }
}
