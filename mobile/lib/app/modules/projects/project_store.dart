import 'package:mobx/mobx.dart';

import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import 'project_model.dart';
import 'project_repository.dart';

class ProjectStore {
  ProjectStore(this._repository);

  final ProjectRepository _repository;

  final projects = ObservableList<ProjectModel>();
  final isLoading = Observable(false);
  final isSaving = Observable(false);
  final error = Observable<String?>(null);

  late final loadProjects = Action(_loadProjects);
  late final createProject = Action(_createProject);
  late final updateProject = Action(_updateProject);
  late final deleteProject = Action(_deleteProject);

  Future<void> _loadProjects() async {
    isLoading.value = true;
    error.value = null;

    try {
      final response = await _repository.list();
      projects
        ..clear()
        ..addAll(response);
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.load.failed', error: exception, stackTrace: stackTrace);
      error.value = errorMessageFor(exception, fallback: 'Não foi possível carregar os projetos.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> _createProject({
    required String name,
    required String description,
  }) async {
    isSaving.value = true;
    error.value = null;

    try {
      final project = await _repository.create(name: name, description: description);
      projects.insert(0, project);
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.create.failed', error: exception, stackTrace: stackTrace);
      error.value = errorMessageFor(exception, fallback: 'Não foi possível criar o projeto.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> _updateProject({
    required ProjectModel project,
    required String name,
    required String description,
  }) async {
    isSaving.value = true;
    error.value = null;

    try {
      final updatedProject = await _repository.update(
        project: project,
        name: name,
        description: description,
      );
      final index = projects.indexWhere((item) => item.id == updatedProject.id);
      if (index >= 0) {
        projects[index] = updatedProject;
      }
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.update.failed', error: exception, stackTrace: stackTrace);
      error.value = errorMessageFor(exception, fallback: 'Não foi possível editar o projeto.');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    error.value = null;
    try {
      await _repository.delete(project);
      projects.removeWhere((item) => item.id == project.id);
    } catch (exception, stackTrace) {
      AppLogger.error(
        'project_store.delete.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': project.id},
      );
      error.value = errorMessageFor(exception, fallback: 'Não foi possível excluir o projeto.');
    }
  }
}
