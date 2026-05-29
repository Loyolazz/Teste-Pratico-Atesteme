import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'task_model.dart';
import 'task_store.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({
    required this.projectId,
    this.projectName,
    super.key,
  });

  final int projectId;
  final String? projectName;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _store = Modular.get<TaskStore>();

  @override
  void initState() {
    super.initState();
    _store.loadTasks(widget.projectId);
  }

  Future<void> _openCreateSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskFormSheet(projectId: widget.projectId, store: _store),
    );
  }

  Future<void> _openEditSheet(TaskModel task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaskFormSheet(projectId: widget.projectId, store: _store, task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.projectName ?? 'Tarefas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.add),
        label: const Text('Tarefa'),
      ),
      body: Observer(
        builder: (_) {
          if (_store.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          final currentError = _store.error.value;
          if (currentError != null && _store.tasks.isEmpty) {
            return Center(child: Text(currentError));
          }

          if (_store.tasks.isEmpty) {
            return const Center(child: Text('Nenhuma tarefa neste projeto.'));
          }

          return Column(
            children: [
              if (currentError != null)
                MaterialBanner(
                  content: Text(currentError),
                  actions: [
                    TextButton(
                      onPressed: () => _store.loadTasks(widget.projectId),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _store.loadTasks(widget.projectId),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _store.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final task = _store.tasks[index];
                      return _TaskTile(
                        task: task,
                        onStatusChanged: (status) => _store.updateStatus(widget.projectId, task, status),
                        onEdit: () => _openEditSheet(task),
                        onDelete: () => _store.deleteTask(widget.projectId, task),
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

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty) Text(task.description!),
          const SizedBox(height: 6),
          Text('Prioridade: ${task.priority.label}'),
        ],
      ),
      trailing: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          DropdownButton<TaskStatus>(
            value: task.status,
            underline: const SizedBox.shrink(),
            items: TaskStatus.values
                .map((status) => DropdownMenuItem(value: status, child: Text(status.label)))
                .toList(),
            onChanged: (status) {
              if (status != null) {
                onStatusChanged(status);
              }
            },
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir',
          ),
        ],
      ),
    );
  }
}

class _TaskFormSheet extends StatefulWidget {
  const _TaskFormSheet({
    required this.projectId,
    required this.store,
    this.task,
  });

  final int projectId;
  final TaskStore store;
  final TaskModel? task;

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  var _priority = TaskPriority.media;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = task.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final task = widget.task;
    final success = task == null
        ? await widget.store.createTask(
            projectId: widget.projectId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
          ) as bool
        : await widget.store.updateTask(
            projectId: widget.projectId,
            task: task,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
          ) as bool;

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
            Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<TaskPriority>(
              value: _priority,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: TaskPriority.values
                  .map((priority) => DropdownMenuItem(value: priority, child: Text(priority.label)))
                  .toList(),
              onChanged: (priority) {
                if (priority != null) {
                  setState(() => _priority = priority);
                }
              },
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (_) => FilledButton.icon(
                onPressed: widget.store.isSaving.value ? null : _submit,
                icon: const Icon(Icons.save),
                label: Text(widget.store.isSaving.value ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
