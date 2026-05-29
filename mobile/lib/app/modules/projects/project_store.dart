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
  final loadingPhase = Observable<String?>(null);
  final savingPhase = Observable<String?>(null);

  Future<void> loadProjects() {
    return _loadProjects();
  }

  Future<bool> createProject({
    required String name,
    required String description,
    required List<String> workers,
  }) {
    return _createProject(
      name: name,
      description: description,
      workers: workers,
    );
  }

  Future<bool> updateProject({
    required ProjectModel project,
    required String name,
    required String description,
    required List<String> workers,
  }) {
    return _updateProject(
      project: project,
      name: name,
      description: description,
      workers: workers,
    );
  }

  Future<void> deleteProject(ProjectModel project) {
    return _deleteProject(project);
  }

  void _setLoadingPhase(String? message,
      {Map<String, Object?> context = const {}}) {
    runInAction(() => loadingPhase.value = message);
    if (message != null) {
      AppLogger.info('project_store.loading_phase',
          context: {'phase': message, ...context});
    }
  }

  void _setSavingPhase(String? message,
      {Map<String, Object?> context = const {}}) {
    runInAction(() => savingPhase.value = message);
    if (message != null) {
      AppLogger.info('project_store.saving_phase',
          context: {'phase': message, ...context});
    }
  }

  Future<void> _loadProjects() async {
    AppLogger.info('project_store.load.started');
    runInAction(() {
      isLoading.value = true;
      error.value = null;
    });
    _setLoadingPhase('Preparando carregamento dos projetos...');

    try {
      _setLoadingPhase('Sincronizando fila offline e buscando projetos...');
      final response = await _repository.list();
      _setLoadingPhase('Atualizando lista de projetos...',
          context: {'items': response.length});
      runInAction(() {
        projects
          ..clear()
          ..addAll(response);
      });
      AppLogger.info('project_store.load.completed',
          context: {'items': response.length});
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.load.failed',
          error: exception, stackTrace: stackTrace);
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível carregar os projetos.');
      });
    } finally {
      runInAction(() {
        isLoading.value = false;
        loadingPhase.value = null;
      });
    }
  }

  Future<bool> _createProject({
    required String name,
    required String description,
    required List<String> workers,
  }) async {
    AppLogger.info('project_store.create.started',
        context: {'name': name, 'workers': workers.length});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Enviando projeto para a API...', context: {'name': name});

    try {
      final project = await _repository.create(
          name: name, description: description, workers: workers);
      _setSavingPhase('Atualizando tela com o projeto...',
          context: {'projectId': project.id});
      runInAction(() => projects.insert(0, project));
      AppLogger.info('project_store.create.completed',
          context: {'projectId': project.id});
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.create.failed',
          error: exception, stackTrace: stackTrace);
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível criar o projeto.');
      });
      return false;
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }

  Future<bool> _updateProject({
    required ProjectModel project,
    required String name,
    required String description,
    required List<String> workers,
  }) async {
    AppLogger.info('project_store.update.started',
        context: {'projectId': project.id, 'name': name});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Enviando alterações do projeto...',
        context: {'projectId': project.id});

    try {
      final updatedProject = await _repository.update(
        project: project,
        name: name,
        description: description,
        workers: workers,
      );
      _setSavingPhase('Aplicando alterações na tela...',
          context: {'projectId': updatedProject.id});
      final index = projects.indexWhere((item) => item.id == updatedProject.id);
      if (index >= 0) {
        runInAction(() => projects[index] = updatedProject);
      }
      AppLogger.info('project_store.update.completed',
          context: {'projectId': updatedProject.id});
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error('project_store.update.failed',
          error: exception, stackTrace: stackTrace);
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível editar o projeto.');
      });
      return false;
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }

  Future<void> _deleteProject(ProjectModel project) async {
    AppLogger.info('project_store.delete.started',
        context: {'projectId': project.id});
    runInAction(() {
      isSaving.value = true;
      error.value = null;
    });
    _setSavingPhase('Excluindo projeto...', context: {'projectId': project.id});
    try {
      await _repository.delete(project);
      _setSavingPhase('Removendo projeto da lista...',
          context: {'projectId': project.id});
      runInAction(() => projects.removeWhere((item) => item.id == project.id));
      AppLogger.info('project_store.delete.completed',
          context: {'projectId': project.id});
    } catch (exception, stackTrace) {
      AppLogger.error(
        'project_store.delete.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'projectId': project.id},
      );
      runInAction(() {
        error.value = errorMessageFor(exception,
            fallback: 'Não foi possível excluir o projeto.');
      });
    } finally {
      runInAction(() {
        isSaving.value = false;
        savingPhase.value = null;
      });
    }
  }
}
