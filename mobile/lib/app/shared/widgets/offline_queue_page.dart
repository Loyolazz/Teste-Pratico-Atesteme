import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../services/app_error.dart';
import '../services/app_logger.dart';
import '../services/offline_sync_service.dart';
import '../storage/local_database.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final operations = await _localDatabase.getPendingOperations();

      if (!mounted) {
        return;
      }

      setState(() {
        _operations = operations;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      AppLogger.error('offline_queue.load.failed', error: error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _message = errorMessageFor(error, fallback: 'Não foi possível carregar a fila offline.');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sync() async {
    setState(() {
      _isSyncing = true;
      _message = null;
    });

    try {
      await _offlineSyncService.syncPendingOperations();
      await _load();
      if (mounted) {
        setState(() => _message = 'Sincronização concluída.');
      }
    } catch (error, stackTrace) {
      AppLogger.error('offline_queue.sync.failed', error: error, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _message = errorMessageFor(error, fallback: 'Não foi possível sincronizar agora.');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar fila offline'),
        content: const Text('As alterações pendentes serão descartadas deste dispositivo.'),
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
      try {
        await _localDatabase.clearPendingOperations();
        await _load();
      } catch (error, stackTrace) {
        AppLogger.error('offline_queue.clear.failed', error: error, stackTrace: stackTrace);
        if (mounted) {
          setState(() {
            _message = errorMessageFor(error, fallback: 'Não foi possível limpar a fila offline.');
          });
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
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
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
                      final operationType = operation['operation_type'] as String;
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
