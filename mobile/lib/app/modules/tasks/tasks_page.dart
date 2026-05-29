import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:mobx/mobx.dart';

import '../../shared/services/app_logger.dart';
import '../../shared/widgets/app_select_field.dart';
import '../../shared/widgets/error_snack_bar.dart';
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
  late final ReactionDisposer _errorDisposer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('screen.tasks.opened', context: {
      'projectId': widget.projectId,
      'projectName': widget.projectName
    });
    _errorDisposer = reaction<String?>(
      (_) => _store.error.value,
      (message) {
        if (message != null) {
          showErrorSnackBar(context, message);
        }
      },
    );
    _store.loadTasks(widget.projectId);
  }

  @override
  void dispose() {
    _errorDisposer();
    super.dispose();
  }

  Future<void> _openCreateSheet() async {
    AppLogger.info('screen.tasks.create_form_opened',
        context: {'projectId': widget.projectId});
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _TaskFormSheet(projectId: widget.projectId, store: _store),
    );
  }

  Future<void> _openEditSheet(TaskModel task) async {
    AppLogger.info('screen.tasks.edit_form_opened',
        context: {'projectId': widget.projectId, 'taskId': task.id});
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: _TaskFormSheet(
          projectId: widget.projectId,
          store: _store,
          task: task,
        ),
      ),
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
            return _LoadingState(
              message: _store.loadingPhase.value ?? 'Carregando tarefas...',
            );
          }

          final currentError = _store.error.value;
          final savingPhase = _store.savingPhase.value;
          if (currentError != null && _store.tasks.isEmpty) {
            return Center(child: Text(currentError));
          }

          if (_store.tasks.isEmpty) {
            return const Center(child: Text('Nenhuma tarefa neste projeto.'));
          }

          return Column(
            children: [
              if (savingPhase != null) _PhaseBanner(message: savingPhase),
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
                        onEdit: () => _openEditSheet(task),
                        onDelete: () {
                          AppLogger.info('screen.tasks.delete_tapped',
                              context: {
                                'projectId': widget.projectId,
                                'taskId': task.id
                              });
                          _store.deleteTask(widget.projectId, task);
                        },
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
    required this.onEdit,
    required this.onDelete,
  });

  final TaskModel task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      leading: Icon(_statusIcon(task.status),
          color: _statusColor(context, task.status)),
      title:
          Text(task.title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (task.description != null && task.description!.isNotEmpty)
            Text(task.description!),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatusBadge(status: task.status),
              _PriorityBadge(priority: task.priority),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_statusIcon(status),
          size: 16, color: _statusColor(context, status)),
      label: Text(status.label),
      visualDensity: VisualDensity.compact,
      backgroundColor: _statusBackground(context, status),
      labelStyle: TextStyle(
        color: _statusColor(context, status),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(priority.label.toUpperCase()),
      visualDensity: VisualDensity.compact,
      backgroundColor: _priorityBackground(context, priority),
      labelStyle: TextStyle(
        color: _priorityColor(context, priority),
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

IconData _statusIcon(TaskStatus status) {
  return switch (status) {
    TaskStatus.pendente => Icons.pending_actions_outlined,
    TaskStatus.emAndamento => Icons.autorenew,
    TaskStatus.concluida => Icons.check_circle_outline,
  };
}

Color _statusColor(BuildContext context, TaskStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    TaskStatus.pendente => const Color(0xFF8A5A00),
    TaskStatus.emAndamento => colors.primary,
    TaskStatus.concluida => colors.primary,
  };
}

Color _statusBackground(BuildContext context, TaskStatus status) {
  final colors = Theme.of(context).colorScheme;
  return switch (status) {
    TaskStatus.pendente => const Color(0xFFFFF7D6),
    TaskStatus.emAndamento => colors.primaryContainer,
    TaskStatus.concluida => colors.secondaryContainer,
  };
}

Color _priorityColor(BuildContext context, TaskPriority priority) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  return switch (priority) {
    TaskPriority.baixa =>
      isDark ? const Color(0xFF9BF2B6) : const Color(0xFF166534),
    TaskPriority.media =>
      isDark ? const Color(0xFFF8D36E) : const Color(0xFF8A5A00),
    TaskPriority.alta =>
      isDark ? const Color(0xFFFDA4AF) : const Color(0xFFB42318),
  };
}

Color _priorityBackground(BuildContext context, TaskPriority priority) {
  final brightness = Theme.of(context).brightness;
  final isDark = brightness == Brightness.dark;
  return switch (priority) {
    TaskPriority.baixa =>
      isDark ? const Color(0xFF173B25) : const Color(0xFFE7F7ED),
    TaskPriority.media =>
      isDark ? const Color(0xFF3B3216) : const Color(0xFFFFF7D6),
    TaskPriority.alta =>
      isDark ? const Color(0xFF451D22) : const Color(0xFFFFE4E6),
  };
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
  var _status = TaskStatus.pendente;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _priority = task.priority;
      _status = task.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    AppLogger.info('screen.tasks.form_submit_tapped', context: {
      'projectId': widget.projectId,
      'mode': widget.task == null ? 'create' : 'edit'
    });
    if (!_formKey.currentState!.validate()) {
      AppLogger.warning('screen.tasks.form_validation_failed',
          context: {'projectId': widget.projectId});
      showErrorSnackBar(context, 'Informe o título da tarefa.');
      return;
    }

    final task = widget.task;
    final success = task == null
        ? await widget.store.createTask(
            projectId: widget.projectId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
            status: _status,
          )
        : await widget.store.updateTask(
            projectId: widget.projectId,
            task: task,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            priority: _priority,
            status: _status,
          );

    if (success && mounted) {
      AppLogger.info('screen.tasks.form_submit_completed',
          context: {'projectId': widget.projectId});
      Navigator.of(context).pop();
    } else {
      AppLogger.warning('screen.tasks.form_submit_not_completed',
          context: {'projectId': widget.projectId});
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
                Text(widget.task == null ? 'Nova tarefa' : 'Editar tarefa',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Informe o título'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                AppSelectField<TaskPriority>(
                  label: 'Prioridade',
                  value: _priority,
                  options: TaskPriority.values
                      .map((priority) => AppSelectOption(
                          value: priority, label: priority.label))
                      .toList(),
                  onChanged: (priority) => setState(() => _priority = priority),
                ),
                const SizedBox(height: 12),
                AppSelectField<TaskStatus>(
                  label: 'Status',
                  value: _status,
                  options: TaskStatus.values
                      .map((status) =>
                          AppSelectOption(value: status, label: status.label))
                      .toList(),
                  onChanged: (status) => setState(() => _status = status),
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
