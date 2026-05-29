import '../../shared/services/api_client.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/services/offline_sync_service.dart';
import '../../shared/storage/local_database.dart';
import 'project_model.dart';

class ProjectRepository {
  const ProjectRepository(this._apiClient, this._localDatabase, this._offlineSyncService);

  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  final OfflineSyncService _offlineSyncService;

  Future<List<ProjectModel>> list() async {
    try {
      await _offlineSyncService.syncPendingOperations();
      final data = await _apiClient.get<List<dynamic>>('/projects');
      final projects = data
          .cast<Map<String, dynamic>>()
          .map(ProjectModel.fromJson)
          .toList();
      await _localDatabase.saveProjects(projects);
      return projects;
    } catch (error, stackTrace) {
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

      AppLogger.error('project.list.failed', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProjectModel> create({
    required String name,
    required String description,
  }) async {
    final payload = {
      'name': name,
      'description': description,
    };

    try {
      final data = await _apiClient.post<Map<String, dynamic>>('/projects', payload);
      final project = ProjectModel.fromJson(data);
      await _localDatabase.upsertProject(project);
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
        createdAt: DateTime.now(),
        taskCount: 0,
      );
      await _localDatabase.upsertProject(project);
      await _localDatabase.addPendingOperation(
        operationType: 'CREATE_PROJECT',
        payload: payload,
        resourceId: project.id,
      );
      return project;
    }
  }

  Future<ProjectModel> update({
    required ProjectModel project,
    required String name,
    required String description,
  }) async {
    final payload = {
      'name': name,
      'description': description,
    };

    try {
      final data = await _apiClient.put<Map<String, dynamic>>('/projects/${project.id}', payload);
      final updatedProject = ProjectModel.fromJson(data);
      await _localDatabase.upsertProject(updatedProject);
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
        createdAt: project.createdAt,
        taskCount: project.taskCount,
      );
      await _localDatabase.upsertProject(updatedProject);
      if (project.id < 0) {
        await _localDatabase.deletePendingOperationsForResource(project.id);
        await _localDatabase.addPendingOperation(
          operationType: 'CREATE_PROJECT',
          payload: payload,
          resourceId: project.id,
        );
        return updatedProject;
      }

      await _localDatabase.addPendingOperation(
        operationType: 'UPDATE_PROJECT',
        payload: payload,
        resourceId: project.id,
      );
      return updatedProject;
    }
  }

  Future<void> delete(ProjectModel project) async {
    try {
      await _apiClient.deleteVoid('/projects/${project.id}');
      await _localDatabase.deleteProject(project.id);
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
      await _localDatabase.deleteProject(project.id);
      if (project.id < 0) {
        await _localDatabase.deletePendingOperationsForProject(project.id);
        return;
      }

      await _localDatabase.addPendingOperation(
        operationType: 'DELETE_PROJECT',
        payload: null,
        resourceId: project.id,
      );
    }
  }
}
