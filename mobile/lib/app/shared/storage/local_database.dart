import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../modules/projects/project_model.dart';
import '../../modules/tasks/task_model.dart';

class LocalDatabase {
  Database? _database;

  Future<void> upsertProject(ProjectModel project) async {
    final db = await database;
    await db.insert('projects', _projectToMap(project), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProject(int projectId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks', where: 'project_id = ?', whereArgs: [projectId]);
      await txn.delete('projects', where: 'id = ?', whereArgs: [projectId]);
    });
  }

  Future<void> saveProjects(List<ProjectModel> projects) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('projects');
      for (final project in projects) {
        await txn.insert('projects', _projectToMap(project), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<ProjectModel>> getProjects() async {
    final db = await database;
    final rows = await db.query('projects', orderBy: 'created_at DESC');
    return rows.map(ProjectModel.fromDatabase).toList();
  }

  Future<ProjectModel?> getProject(int projectId) async {
    final db = await database;
    final rows = await db.query('projects', where: 'id = ?', whereArgs: [projectId], limit: 1);
    if (rows.isEmpty) {
      return null;
    }

    return ProjectModel.fromDatabase(rows.first);
  }

  Future<void> saveTasks(int projectId, List<TaskModel> tasks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('tasks', where: 'project_id = ?', whereArgs: [projectId]);
      for (final task in tasks) {
        await txn.insert('tasks', _taskToMap(task), conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<TaskModel>> getTasks(int projectId) async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'created_at DESC',
    );
    return rows.map(TaskModel.fromDatabase).toList();
  }

  Future<void> upsertTask(TaskModel task) async {
    final db = await database;
    await db.insert('tasks', _taskToMap(task), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteTask(int taskId) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  Future<void> addPendingOperation({
    required String operationType,
    required Map<String, dynamic>? payload,
    int? resourceId,
    int? projectId,
  }) async {
    final db = await database;
    await _resolvePendingOperation(
      db,
      operationType: operationType,
      payload: payload,
      resourceId: resourceId,
      projectId: projectId,
    );
  }

  Future<List<Map<String, Object?>>> getPendingOperations() async {
    final db = await database;
    return db.query('pending_operations', orderBy: 'id ASC');
  }

  Future<void> deletePendingOperation(int operationId) async {
    final db = await database;
    await db.delete('pending_operations', where: 'id = ?', whereArgs: [operationId]);
  }

  Future<void> deletePendingOperationsForResource(int resourceId) async {
    final db = await database;
    await db.delete('pending_operations', where: 'resource_id = ?', whereArgs: [resourceId]);
  }

  Future<void> deletePendingOperationsForProject(int projectId) async {
    final db = await database;
    await db.delete(
      'pending_operations',
      where: 'resource_id = ? OR project_id = ?',
      whereArgs: [projectId, projectId],
    );
  }

  Future<void> replaceProjectReferences({
    required int fromProjectId,
    required int toProjectId,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'tasks',
        {'project_id': toProjectId},
        where: 'project_id = ?',
        whereArgs: [fromProjectId],
      );
      await txn.update(
        'pending_operations',
        {'project_id': toProjectId},
        where: 'project_id = ?',
        whereArgs: [fromProjectId],
      );
      await txn.update(
        'pending_operations',
        {'resource_id': toProjectId},
        where: "resource_id = ? AND operation_type IN ('UPDATE_PROJECT', 'DELETE_PROJECT')",
        whereArgs: [fromProjectId],
      );
    });
  }

  Future<void> clearPendingOperations() async {
    final db = await database;
    await db.delete('pending_operations');
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('tasks');
    await db.delete('projects');
    await db.delete('pending_operations');
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'atesteme_taskmanager.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE projects (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            workers TEXT,
            created_at TEXT NOT NULL,
            task_count INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY,
            project_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            priority TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('CREATE INDEX idx_tasks_project_id ON tasks(project_id)');

        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            resource_id INTEGER,
            project_id INTEGER,
            payload TEXT,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS pending_operations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              operation_type TEXT NOT NULL,
              resource_id INTEGER,
              project_id INTEGER,
              payload TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE projects ADD COLUMN workers TEXT');
        }
      },
    );

    return _database!;
  }

  Map<String, Object?> _projectToMap(ProjectModel project) {
    return {
      'id': project.id,
      'name': project.name,
      'description': project.description,
      'workers': project.workers.join('\n'),
      'created_at': project.createdAt.toIso8601String(),
      'task_count': project.taskCount,
    };
  }

  Map<String, Object?> _taskToMap(TaskModel task) {
    return {
      'id': task.id,
      'project_id': task.projectId,
      'title': task.title,
      'description': task.description,
      'priority': task.priority.value,
      'status': task.status.value,
      'created_at': task.createdAt.toIso8601String(),
    };
  }

  Future<void> _resolvePendingOperation(
    Database db, {
    required String operationType,
    required Map<String, dynamic>? payload,
    required int? resourceId,
    required int? projectId,
  }) async {
    if (resourceId == null) {
      await _insertPendingOperation(
        db,
        operationType: operationType,
        payload: payload,
        resourceId: resourceId,
        projectId: projectId,
      );
      return;
    }

    final existing = await _pendingOperationsForResource(
      db,
      operationType: operationType,
      resourceId: resourceId,
      projectId: projectId,
    );
    final existingDelete = _firstWhereOrNull(existing, (operation) {
      return _isDeleteOperation(operation['operation_type'] as String);
    });

    if (existingDelete != null && !_isDeleteOperation(operationType)) {
      return;
    }

    if (_isDeleteOperation(operationType)) {
      final projectTaskOperations = operationType == 'DELETE_PROJECT'
          ? await _pendingTaskOperationsForProject(db, resourceId)
          : <Map<String, Object?>>[];
      final pendingCreate = _firstWhereOrNull(existing, (operation) {
        return _isCreateOperation(operation['operation_type'] as String);
      });

      await _deletePendingOperationIds(
        db,
        [
          ...existing,
          ...projectTaskOperations,
        ].map((operation) => operation['id'] as int),
      );

      if (pendingCreate != null || resourceId < 0) {
        return;
      }

      await _insertPendingOperation(
        db,
        operationType: operationType,
        payload: payload,
        resourceId: resourceId,
        projectId: projectId,
      );
      return;
    }

    final pendingCreate = _firstWhereOrNull(existing, (operation) {
      return _isCreateOperation(operation['operation_type'] as String);
    });
    if (pendingCreate != null) {
      await _updatePendingOperationPayload(
        db,
        pendingCreate['id'] as int,
        _mergePayload(
          decodeOperationPayload(pendingCreate['payload']),
          payload,
          operationType,
        ),
      );
      await _deletePendingOperationIds(
        db,
        existing
            .where((operation) => operation['id'] != pendingCreate['id'])
            .map((operation) => operation['id'] as int),
      );
      return;
    }

    if (operationType == 'UPDATE_TASK_STATUS') {
      final pendingTaskUpdate = _firstWhereOrNull(existing, (operation) {
        return operation['operation_type'] == 'UPDATE_TASK';
      });
      if (pendingTaskUpdate != null) {
        await _updatePendingOperationPayload(
          db,
          pendingTaskUpdate['id'] as int,
          _mergePayload(
            decodeOperationPayload(pendingTaskUpdate['payload']),
            payload,
            operationType,
          ),
        );
        await _deletePendingOperationIds(
          db,
          existing
              .where((operation) => operation['operation_type'] == 'UPDATE_TASK_STATUS')
              .map((operation) => operation['id'] as int),
        );
        return;
      }
    }

    final replaceableTypes = _replaceableOperationTypes(operationType);
    await _deletePendingOperationIds(
      db,
      existing
          .where((operation) => replaceableTypes.contains(operation['operation_type']))
          .map((operation) => operation['id'] as int),
    );
    await _insertPendingOperation(
      db,
      operationType: operationType,
      payload: payload,
      resourceId: resourceId,
      projectId: projectId,
    );
  }

  Future<void> _insertPendingOperation(
    Database db, {
    required String operationType,
    required Map<String, dynamic>? payload,
    required int? resourceId,
    required int? projectId,
  }) async {
    await db.insert('pending_operations', {
      'operation_type': operationType,
      'resource_id': resourceId,
      'project_id': projectId,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _updatePendingOperationPayload(
    Database db,
    int operationId,
    Map<String, dynamic>? payload,
  ) async {
    await db.update(
      'pending_operations',
      {
        'payload': payload == null ? null : jsonEncode(payload),
        'created_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [operationId],
    );
  }

  Future<void> _deletePendingOperationIds(Database db, Iterable<int> operationIds) async {
    for (final operationId in operationIds.toSet()) {
      await db.delete('pending_operations', where: 'id = ?', whereArgs: [operationId]);
    }
  }

  Future<List<Map<String, Object?>>> _pendingOperationsForResource(
    Database db, {
    required String operationType,
    required int resourceId,
    required int? projectId,
  }) async {
    final rows = await db.query(
      'pending_operations',
      where: 'resource_id = ?',
      whereArgs: [resourceId],
      orderBy: 'id ASC',
    );

    return rows.where((operation) {
      final existingType = operation['operation_type'] as String;
      if (_isProjectOperation(operationType) != _isProjectOperation(existingType)) {
        return false;
      }

      return _isProjectOperation(operationType) || projectId == null || operation['project_id'] == projectId;
    }).toList();
  }

  Future<List<Map<String, Object?>>> _pendingTaskOperationsForProject(Database db, int projectId) async {
    final rows = await db.query(
      'pending_operations',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: 'id ASC',
    );

    return rows.where((operation) {
      return _isTaskOperation(operation['operation_type'] as String);
    }).toList();
  }

  List<String> _replaceableOperationTypes(String operationType) {
    switch (operationType) {
      case 'UPDATE_PROJECT':
        return ['UPDATE_PROJECT'];
      case 'UPDATE_TASK':
        return ['UPDATE_TASK', 'UPDATE_TASK_STATUS'];
      case 'UPDATE_TASK_STATUS':
        return ['UPDATE_TASK_STATUS'];
      default:
        return [operationType];
    }
  }

  Map<String, dynamic>? _mergePayload(
    Map<String, dynamic>? current,
    Map<String, dynamic>? next,
    String operationType,
  ) {
    final merged = <String, dynamic>{
      if (current != null) ...current,
    };

    if (operationType == 'UPDATE_TASK_STATUS') {
      if (next != null && next.containsKey('status')) {
        merged['status'] = next['status'];
      }

      return merged.isEmpty ? next : merged;
    }

    if (next != null) {
      merged.addAll(next);
    }

    return merged.isEmpty ? null : merged;
  }

  Map<String, Object?>? _firstWhereOrNull(
    Iterable<Map<String, Object?>> operations,
    bool Function(Map<String, Object?> operation) test,
  ) {
    for (final operation in operations) {
      if (test(operation)) {
        return operation;
      }
    }

    return null;
  }

  bool _isCreateOperation(String operationType) {
    return operationType == 'CREATE_PROJECT' || operationType == 'CREATE_TASK';
  }

  bool _isDeleteOperation(String operationType) {
    return operationType == 'DELETE_PROJECT' || operationType == 'DELETE_TASK';
  }

  bool _isProjectOperation(String operationType) {
    return operationType.endsWith('_PROJECT');
  }

  bool _isTaskOperation(String operationType) {
    return !_isProjectOperation(operationType);
  }
}

Map<String, dynamic>? decodeOperationPayload(Object? payload) {
  if (payload == null) {
    return null;
  }

  return jsonDecode(payload as String) as Map<String, dynamic>;
}
