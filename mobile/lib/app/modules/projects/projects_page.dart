import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/error_snack_bar.dart';
import '../auth/auth_store.dart';
import '../users/user_model.dart';
import '../users/user_repository.dart';
import 'project_model.dart';
import 'project_store.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  final _projectStore = Modular.get<ProjectStore>();
  final _authStore = Modular.get<AuthStore>();
  final _userRepository = Modular.get<UserRepository>();
  var _registeredUsers = <UserModel>[];
  late final ReactionDisposer _errorDisposer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('screen.projects.opened');
    _errorDisposer = reaction<String?>(
      (_) => _projectStore.error.value,
      (message) {
        if (message != null) {
          showErrorSnackBar(context, message);
        }
      },
    );
    _projectStore.loadProjects();
    _loadRegisteredUsers();
  }

  @override
  void dispose() {
    _errorDisposer();
    super.dispose();
  }

  Future<void> _logout() async {
    AppLogger.info('screen.projects.logout_tapped');
    await _authStore.logout();
    Modular.to.navigate('/auth/login');
  }

  Future<void> _loadRegisteredUsers() async {
    AppLogger.info('screen.projects.users_load.started');
    try {
      final users = await _userRepository.listAssignable();
      AppLogger.info('screen.projects.users_load.completed',
          context: {'items': users.length});
      if (mounted) {
        setState(() => _registeredUsers = users);
      }
    } catch (error, stackTrace) {
      AppLogger.error('screen.projects.users_load.failed',
          error: error, stackTrace: stackTrace);
      if (mounted) {
        showErrorSnackBar(
          context,
          errorMessageFor(error,
              fallback: 'Não foi possível carregar os usuários.'),
        );
      }
    }
  }

  void _openTasks(ProjectModel project) {
    AppLogger.info('screen.projects.open_tasks',
        context: {'projectId': project.id});
    if (project.id < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sincronize o projeto antes de gerenciar tarefas.')),
      );
      return;
    }

    Modular.to.pushNamed('/tasks/${project.id}', arguments: project.name);
  }

  Future<void> _openProjectForm([ProjectModel? project]) async {
    AppLogger.info('screen.projects.form_opened', context: {
      'projectId': project?.id,
      'mode': project == null ? 'create' : 'edit'
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectFormSheet(
        store: _projectStore,
        project: project,
        registeredUsers: _registeredUsers,
      ),
    );
  }

  Future<void> _deleteProject(ProjectModel project) async {
    AppLogger.info('screen.projects.delete_confirm_opened',
        context: {'projectId': project.id});
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir projeto'),
        content: Text('Excluir "${project.name}" e suas tarefas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppLogger.info('screen.projects.delete_confirmed',
          context: {'projectId': project.id});
      await _projectStore.deleteProject(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projetos'),
        actions: [
          IconButton(
            onPressed: () => Modular.to.pushNamed('/offline/'),
            icon: const Icon(Icons.sync),
            tooltip: 'Fila offline',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProjectForm(),
        icon: const Icon(Icons.add),
        label: const Text('Projeto'),
      ),
      body: Observer(
        builder: (_) {
          if (_projectStore.isLoading.value) {
            return _LoadingState(
              message:
                  _projectStore.loadingPhase.value ?? 'Carregando projetos...',
            );
          }

          final currentError = _projectStore.error.value;
          final savingPhase = _projectStore.savingPhase.value;
          if (currentError != null && _projectStore.projects.isEmpty) {
            return _MessageState(
              message: currentError,
              onRetry: () => _projectStore.loadProjects(),
            );
          }

          if (_projectStore.projects.isEmpty) {
            return _MessageState(
              message: 'Nenhum projeto cadastrado.',
              onRetry: () => _projectStore.loadProjects(),
            );
          }

          return Column(
            children: [
              if (savingPhase != null) _PhaseBanner(message: savingPhase),
              if (currentError != null)
                MaterialBanner(
                  content: Text(currentError),
                  actions: [
                    TextButton(
                      onPressed: () => _projectStore.loadProjects(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _projectStore.loadProjects(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projectStore.projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final project = _projectStore.projects[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side:
                              BorderSide(color: Theme.of(context).dividerColor),
                        ),
                        title: Text(project.name),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${project.taskCount} tarefas'),
                              if (project.workers.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: project.workers
                                      .map((worker) =>
                                          _WorkerChip(label: worker))
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () => _openProjectForm(project),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Editar',
                            ),
                            IconButton(
                              onPressed: () => _deleteProject(project),
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir',
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => _openTasks(project),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectFormSheet extends StatefulWidget {
  const _ProjectFormSheet({
    required this.store,
    required this.registeredUsers,
    this.project,
  });

  final ProjectStore store;
  final List<UserModel> registeredUsers;
  final ProjectModel? project;

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _externalWorkerController = TextEditingController();
  final _workers = <String>[];
  var _selectedUserId = -1;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project != null) {
      _nameController.text = project.name;
      _descriptionController.text = project.description ?? '';
      _workers.addAll(project.workers);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _externalWorkerController.dispose();
    super.dispose();
  }

  void _addWorker(String name) {
    final worker = name.trim();
    if (worker.isEmpty || _workers.contains(worker)) {
      return;
    }

    setState(() => _workers.add(worker));
  }

  void _addExternalWorker() {
    _addWorker(_externalWorkerController.text);
    _externalWorkerController.clear();
  }

  void _selectRegisteredUser(int userId) {
    UserModel? user;
    for (final candidate in widget.registeredUsers) {
      if (candidate.id == userId) {
        user = candidate;
        break;
      }
    }
    if (user != null) {
      _addWorker(user.name);
    }
    setState(() => _selectedUserId = -1);
  }

  Future<void> _submit() async {
    AppLogger.info('screen.projects.form_submit_tapped',
        context: {'mode': widget.project == null ? 'create' : 'edit'});
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('screen.projects.form_validation_failed');
      showErrorSnackBar(context, 'Informe o nome do projeto.');
      return;
    }

    final project = widget.project;
    final success = project == null
        ? await widget.store.createProject(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            workers: _workers,
          )
        : await widget.store.updateProject(
            project: project,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            workers: _workers,
          );

    if (success && mounted) {
      AppLogger.info('screen.projects.form_submit_completed');
      Navigator.of(context).pop();
    } else {
      AppLogger.warning('screen.projects.form_submit_not_completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom:
                mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.project == null ? 'Novo projeto' : 'Editar projeto',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Text(
                  'Equipe no projeto',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                AppSelectField<int>(
                  label: 'Usuário cadastrado',
                  value: _selectedUserId,
                  options: [
                    const AppSelectOption(
                        value: -1, label: 'Selecionar usuário'),
                    ...widget.registeredUsers.map(
                      (user) => AppSelectOption(
                        value: user.id,
                        label: '${user.name} · ${user.email}',
                      ),
                    ),
                  ],
                  onChanged: _selectRegisteredUser,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _externalWorkerController,
                        decoration:
                            const InputDecoration(labelText: 'Nome externo'),
                        onFieldSubmitted: (_) => _addExternalWorker(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _addExternalWorker,
                      icon: const Icon(Icons.add),
                      tooltip: 'Adicionar pessoa',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_workers.isEmpty)
                  Text(
                    'Ninguém informado ainda.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _workers
                        .map(
                          (worker) => InputChip(
                            label: Text(worker),
                            onDeleted: () =>
                                setState(() => _workers.remove(worker)),
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 16),
                Observer(
                  builder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: widget.store.isSaving.value ? null : _submit,
                        icon: const Icon(Icons.save),
                        label: Text(widget.store.isSaving.value
                            ? 'Salvando...'
                            : 'Salvar'),
                      ),
                      if (widget.store.savingPhase.value != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.store.savingPhase.value!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      content: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      actions: const [SizedBox.shrink()],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerChip extends StatelessWidget {
  const _WorkerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colors.tertiaryContainer,
      labelStyle: TextStyle(
        color: colors.onTertiaryContainer,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
