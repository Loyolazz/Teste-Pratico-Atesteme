import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../services/app_error.dart';
import '../services/app_logger.dart';
import '../services/offline_sync_service.dart';
import '../storage/local_database.dart';
import 'error_snack_bar.dart';

class OfflineQueuePage extends StatefulWidget {
  const OfflineQueuePage({super.key});

  @override
  State<OfflineQueuePage> createState() => _OfflineQueuePageState();
}

class _OfflineQueuePageState extends State<OfflineQueuePage> {
  final _localDatabase = Modular.get<LocalDatabase>();
  final _offlineSyncService = Modular.get<OfflineSyncService>();
  var _operations = <Map<String, Object?>>[];
  var _isLoading = true;
  var _isSyncing = false;
  String? _message;
  String? _phase;

  @override
  void initState() {
    super.initState();
    AppLogger.info('screen.offline_queue.opened');
    _load();
  }

  Future<void> _load() async {
    AppLogger.info('screen.offline_queue.load.started');
    setState(() {
      _isLoading = true;
      _message = null;
      _phase = 'Lendo alterações salvas no aparelho...';
    });

    try {
      final operations = await _localDatabase.getPendingOperations();
      AppLogger.info('screen.offline_queue.load.completed',
          context: {'items': operations.length});

      if (!mounted) {
        return;
      }

      setState(() {
        _operations = operations;
        _isLoading = false;
        _phase = null;
      });
    } catch (error, stackTrace) {
      AppLogger.error('offline_queue.load.failed',
          error: error, stackTrace: stackTrace);
      if (mounted) {
        final message = errorMessageFor(error,
            fallback: 'Não foi possível carregar a fila offline.');
        setState(() {
          _message = message;
          _isLoading = false;
          _phase = null;
        });
        showErrorSnackBar(context, message);
      }
    }
  }

  Future<void> _sync() async {
    AppLogger.info('screen.offline_queue.sync.started',
        context: {'items': _operations.length});
    setState(() {
      _isSyncing = true;
      _message = null;
      _phase = 'Enviando fila offline para a API...';
    });

    try {
      await _offlineSyncService.syncPendingOperations();
      if (mounted) {
        setState(() => _phase = 'Atualizando a fila local...');
      }
      await _load();
      if (mounted) {
        setState(() => _message = 'Sincronização concluída.');
      }
      AppLogger.info('screen.offline_queue.sync.completed');
    } catch (error, stackTrace) {
      AppLogger.error('offline_queue.sync.failed',
          error: error, stackTrace: stackTrace);
      if (mounted) {
        final message = errorMessageFor(error,
            fallback: 'Não foi possível sincronizar agora.');
        setState(() {
          _message = message;
          _phase = null;
        });
        showErrorSnackBar(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _phase = null;
        });
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar fila offline'),
        content: const Text(
            'As alterações pendentes serão descartadas deste dispositivo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      AppLogger.info('screen.offline_queue.clear.started',
          context: {'items': _operations.length});
      try {
        setState(() => _phase = 'Limpando alterações pendentes...');
        await _localDatabase.clearPendingOperations();
        await _load();
        AppLogger.info('screen.offline_queue.clear.completed');
      } catch (error, stackTrace) {
        AppLogger.error('offline_queue.clear.failed',
            error: error, stackTrace: stackTrace);
        if (mounted) {
          final message = errorMessageFor(error,
              fallback: 'Não foi possível limpar a fila offline.');
          setState(() {
            _message = message;
            _phase = null;
          });
          showErrorSnackBar(context, message);
        }
      }
    }
  }

  String _labelFor(String operationType) {
    return switch (operationType) {
      'CREATE_PROJECT' => 'Criar projeto',
      'UPDATE_PROJECT' => 'Editar projeto',
      'DELETE_PROJECT' => 'Excluir projeto',
      'CREATE_TASK' => 'Criar tarefa',
      'UPDATE_TASK' => 'Editar tarefa',
      'UPDATE_TASK_STATUS' => 'Atualizar status',
      'DELETE_TASK' => 'Excluir tarefa',
      _ => operationType,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila offline'),
        actions: [
          IconButton(
            onPressed: _operations.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Limpar fila',
          ),
        ],
      ),
      body: _isLoading
          ? _LoadingState(message: _phase ?? 'Carregando fila offline...')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  if (_phase != null) ...[
                    _PhaseCard(message: _phase!),
                    const SizedBox(height: 12),
                  ],
                  if (_message != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_message!),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_operations.isEmpty)
                    const _EmptyQueue()
                  else
                    ..._operations.map((operation) {
                      final operationType =
                          operation['operation_type'] as String;
                      final createdAt = operation['created_at'] as String;
                      return Card(
                        child: ListTile(
                          title: Text(_labelFor(operationType)),
                          subtitle: Text('Criada em $createdAt'),
                          trailing: Text('#${operation['id']}'),
                        ),
                      );
                    }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _operations.isEmpty || _isSyncing ? null : _sync,
        icon: _isSyncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
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

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.cloud_done_outlined, size: 48),
          SizedBox(height: 12),
          Text('Nenhuma alteração pendente.'),
        ],
      ),
    );
  }
}
