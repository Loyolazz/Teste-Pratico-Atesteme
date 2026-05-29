import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/widgets/error_snack_bar.dart';
import '../auth/auth_store.dart';
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
  late final ReactionDisposer _errorDisposer;

  @override
  void initState() {
    super.initState();
    _errorDisposer = reaction<String?>(
      (_) => _projectStore.error.value,
      (message) {
        if (message != null) {
          showErrorSnackBar(context, message);
        }
      },
    );
    _projectStore.loadProjects();
  }

  @override
  void dispose() {
    _errorDisposer();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authStore.logout();
    Modular.to.navigate('/auth/login');
  }

  void _openTasks(ProjectModel project) {
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProjectFormSheet(store: _projectStore, project: project),
    );
  }

  Future<void> _deleteProject(ProjectModel project) async {
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
            return const Center(child: CircularProgressIndicator());
          }

          final currentError = _projectStore.error.value;
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
                        subtitle: Text('${project.taskCount} tarefas'),
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
    this.project,
  });

  final ProjectStore store;
  final ProjectModel? project;

  @override
  State<_ProjectFormSheet> createState() => _ProjectFormSheetState();
}

class _ProjectFormSheetState extends State<_ProjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project != null) {
      _nameController.text = project.name;
      _descriptionController.text = project.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      showErrorSnackBar(context, 'Informe o nome do projeto.');
      return;
    }

    final project = widget.project;
    final success = project == null
        ? await widget.store.createProject(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          )
        : await widget.store.updateProject(
            project: project,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
            const SizedBox(height: 16),
            Observer(
              builder: (_) => FilledButton.icon(
                onPressed: widget.store.isSaving.value ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(
                    widget.store.isSaving.value ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
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
