import initSqlJs from 'sql.js';
import { get, set, del } from 'idb-keyval';
import sqliteWasmUrl from 'sql.js/dist/sql-wasm.wasm?url';
import type { Project, Task } from '../types/api';

const DB_KEY = 'atesteme-taskmanager-sqlite';

type Database = initSqlJs.Database;
type SqlJsStatic = initSqlJs.SqlJsStatic;
type SqlValue = initSqlJs.SqlValue;
type QueryRow = Record<string, SqlValue>;

export type PendingOperationType =
  | 'CREATE_PROJECT'
  | 'UPDATE_PROJECT'
  | 'DELETE_PROJECT'
  | 'CREATE_TASK'
  | 'UPDATE_TASK'
  | 'UPDATE_TASK_STATUS'
  | 'DELETE_TASK';

export type PendingOperation = {
  id: number;
  operationType: PendingOperationType;
  resourceId: number | null;
  projectId: number | null;
  payload: Record<string, unknown> | null;
  createdAt: string;
};

class LocalDatabase {
  private databasePromise: Promise<Database> | null = null;
  private sqlPromise: Promise<SqlJsStatic> | null = null;

  async saveProjects(projects: Project[]) {
    const db = await this.database();
    db.run('DELETE FROM projects');

    const statement = db.prepare(`
      INSERT INTO projects (id, name, description, workers, created_at, task_count)
      VALUES (?, ?, ?, ?, ?, ?)
    `);

    try {
      projects.forEach((project) => {
        statement.run([
          project.id,
          project.name,
          project.description ?? null,
          JSON.stringify(project.workers ?? []),
          project.createdAt,
          project.taskCount
        ]);
      });
    } finally {
      statement.free();
    }

    await this.persist();
  }

  async upsertProject(project: Project) {
    const db = await this.database();
    db.run(`
      INSERT INTO projects (id, name, description, workers, created_at, task_count)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        description = excluded.description,
        workers = excluded.workers,
        created_at = excluded.created_at,
        task_count = excluded.task_count
    `, [
      project.id,
      project.name,
      project.description ?? null,
      JSON.stringify(project.workers ?? []),
      project.createdAt,
      project.taskCount
    ]);
    await this.persist();
  }

  async deleteProject(projectId: number) {
    const db = await this.database();
    db.run('DELETE FROM tasks WHERE project_id = ?', [projectId]);
    db.run('DELETE FROM projects WHERE id = ?', [projectId]);
    await this.persist();
  }

  async getProjects() {
    const db = await this.database();
    return this.query<Project>(db, `
      SELECT id, name, description, workers, created_at, task_count
      FROM projects
      ORDER BY datetime(created_at) DESC
    `, (row) => ({
      id: Number(row.id),
      name: String(row.name),
      description: row.description === null ? null : String(row.description),
      workers: this.parseWorkers(row.workers),
      createdAt: String(row.created_at),
      taskCount: Number(row.task_count)
    }));
  }

  async getProject(projectId: number) {
    const projects = await this.getProjects();
    return projects.find((project) => project.id === projectId) ?? null;
  }

  async saveTasks(projectId: number, tasks: Task[]) {
    const db = await this.database();
    db.run('DELETE FROM tasks WHERE project_id = ?', [projectId]);

    const statement = db.prepare(`
      INSERT INTO tasks (id, project_id, title, description, priority, status, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    try {
      tasks.forEach((task) => {
        statement.run([
          task.id,
          task.projectId,
          task.title,
          task.description ?? null,
          task.priority,
          task.status,
          task.createdAt
        ]);
      });
    } finally {
      statement.free();
    }

    await this.persist();
  }

  async upsertTask(task: Task) {
    const db = await this.database();
    db.run(`
      INSERT INTO tasks (id, project_id, title, description, priority, status, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        project_id = excluded.project_id,
        title = excluded.title,
        description = excluded.description,
        priority = excluded.priority,
        status = excluded.status,
        created_at = excluded.created_at
    `, [
      task.id,
      task.projectId,
      task.title,
      task.description ?? null,
      task.priority,
      task.status,
      task.createdAt
    ]);
    await this.persist();
  }

  async deleteTask(taskId: number) {
    const db = await this.database();
    db.run('DELETE FROM tasks WHERE id = ?', [taskId]);
    await this.persist();
  }

  async getTasks(projectId: number) {
    const db = await this.database();
    return this.query<Task>(db, `
      SELECT id, project_id, title, description, priority, status, created_at
      FROM tasks
      WHERE project_id = ?
      ORDER BY datetime(created_at) DESC
    `, (row) => ({
      id: Number(row.id),
      projectId: Number(row.project_id),
      title: String(row.title),
      description: row.description === null ? null : String(row.description),
      priority: row.priority as Task['priority'],
      status: row.status as Task['status'],
      createdAt: String(row.created_at)
    }), [projectId]);
  }

  async getTask(projectId: number, taskId: number) {
    const tasks = await this.getTasks(projectId);
    return tasks.find((task) => task.id === taskId) ?? null;
  }

  async addPendingOperation(
    operationType: PendingOperationType,
    payload: Record<string, unknown> | null,
    options: { resourceId?: number; projectId?: number } = {}
  ) {
    const db = await this.database();
    this.resolvePendingOperation(db, operationType, payload, options);
    await this.persist();
  }

  async getPendingOperations() {
    const db = await this.database();
    return this.query<PendingOperation>(db, `
      SELECT id, operation_type, resource_id, project_id, payload, created_at
      FROM pending_operations
      ORDER BY id ASC
    `, (row) => ({
      id: Number(row.id),
      operationType: row.operation_type as PendingOperationType,
      resourceId: row.resource_id === null ? null : Number(row.resource_id),
      projectId: row.project_id === null ? null : Number(row.project_id),
      payload: row.payload === null ? null : JSON.parse(String(row.payload)) as Record<string, unknown>,
      createdAt: String(row.created_at)
    }));
  }

  async deletePendingOperation(operationId: number) {
    const db = await this.database();
    db.run('DELETE FROM pending_operations WHERE id = ?', [operationId]);
    await this.persist();
  }

  async deletePendingOperationsForResource(resourceId: number) {
    const db = await this.database();
    db.run('DELETE FROM pending_operations WHERE resource_id = ?', [resourceId]);
    await this.persist();
  }

  async deletePendingOperationsForProject(projectId: number) {
    const db = await this.database();
    db.run('DELETE FROM pending_operations WHERE resource_id = ? OR project_id = ?', [projectId, projectId]);
    await this.persist();
  }

  async replaceProjectReferences(fromProjectId: number, toProjectId: number) {
    const db = await this.database();
    db.run('UPDATE tasks SET project_id = ? WHERE project_id = ?', [toProjectId, fromProjectId]);
    db.run('UPDATE pending_operations SET project_id = ? WHERE project_id = ?', [toProjectId, fromProjectId]);
    db.run(`
      UPDATE pending_operations
      SET resource_id = ?
      WHERE resource_id = ?
        AND operation_type IN ('UPDATE_PROJECT', 'DELETE_PROJECT')
    `, [toProjectId, fromProjectId]);
    await this.persist();
  }

  async clearAll() {
    const db = await this.database();
    db.run('DELETE FROM tasks');
    db.run('DELETE FROM projects');
    db.run('DELETE FROM pending_operations');
    await this.persist();
    await del(DB_KEY);
  }

  private async database() {
    if (!this.databasePromise) {
      this.databasePromise = this.createDatabase();
    }

    return this.databasePromise;
  }

  private async createDatabase() {
    const SQL = await this.sql();
    const persisted = await get<Uint8Array>(DB_KEY);
    const db = persisted ? new SQL.Database(persisted) : new SQL.Database();
    this.createSchema(db);
    return db;
  }

  private async sql() {
    if (!this.sqlPromise) {
      this.sqlPromise = initSqlJs({
        locateFile: () => sqliteWasmUrl
      });
    }

    return this.sqlPromise;
  }

  private createSchema(db: Database) {
    db.run(`
      CREATE TABLE IF NOT EXISTS projects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        workers TEXT,
        created_at TEXT NOT NULL,
        task_count INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY,
        project_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        priority TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);

      CREATE TABLE IF NOT EXISTS pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        resource_id INTEGER,
        project_id INTEGER,
        payload TEXT,
        created_at TEXT NOT NULL
      );
    `);
    this.ensureColumn(db, 'projects', 'workers', 'TEXT');
  }

  private ensureColumn(db: Database, table: string, column: string, definition: string) {
    const columns = this.query<string>(
      db,
      `PRAGMA table_info(${table})`,
      (row) => String(row.name)
    );

    if (!columns.includes(column)) {
      db.run(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
    }
  }

  private parseWorkers(value: SqlValue) {
    if (value === null) {
      return [];
    }

    try {
      const parsed = JSON.parse(String(value)) as unknown;
      return Array.isArray(parsed)
        ? parsed.filter((worker): worker is string => typeof worker === 'string')
        : [];
    } catch {
      return [];
    }
  }

  private resolvePendingOperation(
    db: Database,
    operationType: PendingOperationType,
    payload: Record<string, unknown> | null,
    options: { resourceId?: number; projectId?: number }
  ) {
    const resourceId = options.resourceId ?? null;
    const projectId = options.projectId ?? null;

    if (resourceId === null) {
      this.insertPendingOperation(db, operationType, payload, resourceId, projectId);
      return;
    }

    const existing = this.pendingOperationsForResource(db, operationType, resourceId, projectId);
    const existingDelete = existing.find((operation) => this.isDeleteOperation(operation.operationType));

    if (existingDelete && !this.isDeleteOperation(operationType)) {
      return;
    }

    if (this.isDeleteOperation(operationType)) {
      const projectTaskOperations = operationType === 'DELETE_PROJECT'
        ? this.pendingTaskOperationsForProject(db, resourceId)
        : [];
      const operationsToRemove = [...existing, ...projectTaskOperations];
      const pendingCreate = existing.find((operation) => this.isCreateOperation(operation.operationType));

      this.deletePendingOperationsByIds(db, operationsToRemove.map((operation) => operation.id));

      if (pendingCreate || resourceId < 0) {
        return;
      }

      this.insertPendingOperation(db, operationType, payload, resourceId, projectId);
      return;
    }

    const pendingCreate = existing.find((operation) => this.isCreateOperation(operation.operationType));
    if (pendingCreate) {
      this.updatePendingOperationPayload(
        db,
        pendingCreate.id,
        this.mergePayload(pendingCreate.payload, payload, operationType)
      );
      this.deletePendingOperationsByIds(
        db,
        existing
          .filter((operation) => operation.id !== pendingCreate.id)
          .map((operation) => operation.id)
      );
      return;
    }

    if (operationType === 'UPDATE_TASK_STATUS') {
      const pendingTaskUpdate = existing.find((operation) => operation.operationType === 'UPDATE_TASK');
      if (pendingTaskUpdate) {
        this.updatePendingOperationPayload(
          db,
          pendingTaskUpdate.id,
          this.mergePayload(pendingTaskUpdate.payload, payload, operationType)
        );
        this.deletePendingOperationsByIds(
          db,
          existing
            .filter((operation) => operation.operationType === 'UPDATE_TASK_STATUS')
            .map((operation) => operation.id)
        );
        return;
      }
    }

    const replaceableTypes = this.replaceableOperationTypes(operationType);
    this.deletePendingOperationsByIds(
      db,
      existing
        .filter((operation) => replaceableTypes.includes(operation.operationType))
        .map((operation) => operation.id)
    );
    this.insertPendingOperation(db, operationType, payload, resourceId, projectId);
  }

  private insertPendingOperation(
    db: Database,
    operationType: PendingOperationType,
    payload: Record<string, unknown> | null,
    resourceId: number | null,
    projectId: number | null
  ) {
    db.run(`
      INSERT INTO pending_operations (operation_type, resource_id, project_id, payload, created_at)
      VALUES (?, ?, ?, ?, ?)
    `, [
      operationType,
      resourceId,
      projectId,
      payload ? JSON.stringify(payload) : null,
      new Date().toISOString()
    ]);
  }

  private updatePendingOperationPayload(
    db: Database,
    operationId: number,
    payload: Record<string, unknown> | null
  ) {
    db.run('UPDATE pending_operations SET payload = ?, created_at = ? WHERE id = ?', [
      payload ? JSON.stringify(payload) : null,
      new Date().toISOString(),
      operationId
    ]);
  }

  private deletePendingOperationsByIds(db: Database, operationIds: number[]) {
    [...new Set(operationIds)].forEach((operationId) => {
      db.run('DELETE FROM pending_operations WHERE id = ?', [operationId]);
    });
  }

  private pendingOperationsForResource(
    db: Database,
    operationType: PendingOperationType,
    resourceId: number,
    projectId: number | null
  ) {
    return this.query<PendingOperation>(db, `
      SELECT id, operation_type, resource_id, project_id, payload, created_at
      FROM pending_operations
      WHERE resource_id = ?
      ORDER BY id ASC
    `, (row) => this.mapPendingOperation(row), [resourceId])
      .filter((operation) => {
        if (this.isProjectOperation(operationType) !== this.isProjectOperation(operation.operationType)) {
          return false;
        }

        return this.isProjectOperation(operationType)
          || projectId === null
          || operation.projectId === projectId;
      });
  }

  private pendingTaskOperationsForProject(db: Database, projectId: number) {
    return this.query<PendingOperation>(db, `
      SELECT id, operation_type, resource_id, project_id, payload, created_at
      FROM pending_operations
      WHERE project_id = ?
      ORDER BY id ASC
    `, (row) => this.mapPendingOperation(row), [projectId])
      .filter((operation) => this.isTaskOperation(operation.operationType));
  }

  private replaceableOperationTypes(operationType: PendingOperationType) {
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

  private mergePayload(
    current: Record<string, unknown> | null,
    next: Record<string, unknown> | null,
    operationType: PendingOperationType
  ) {
    const merged = { ...(current ?? {}) };

    if (operationType === 'UPDATE_TASK_STATUS') {
      if (next && 'status' in next) {
        merged.status = next.status;
      }

      return Object.keys(merged).length ? merged : next;
    }

    return {
      ...merged,
      ...(next ?? {})
    };
  }

  private mapPendingOperation(row: QueryRow): PendingOperation {
    return {
      id: Number(row.id),
      operationType: row.operation_type as PendingOperationType,
      resourceId: row.resource_id === null ? null : Number(row.resource_id),
      projectId: row.project_id === null ? null : Number(row.project_id),
      payload: row.payload === null ? null : JSON.parse(String(row.payload)) as Record<string, unknown>,
      createdAt: String(row.created_at)
    };
  }

  private isCreateOperation(operationType: PendingOperationType) {
    return operationType === 'CREATE_PROJECT' || operationType === 'CREATE_TASK';
  }

  private isDeleteOperation(operationType: PendingOperationType) {
    return operationType === 'DELETE_PROJECT' || operationType === 'DELETE_TASK';
  }

  private isProjectOperation(operationType: PendingOperationType) {
    return operationType.endsWith('_PROJECT');
  }

  private isTaskOperation(operationType: PendingOperationType) {
    return !this.isProjectOperation(operationType);
  }

  private async persist() {
    const db = await this.database();
    // O banco local é cache de UX/offline; o backend segue como fonte das regras sensíveis.
    await set(DB_KEY, db.export());
  }

  private query<T>(
    db: Database,
    sql: string,
    mapper: (row: QueryRow) => T,
    params: SqlValue[] = []
  ) {
    const statement = db.prepare(sql, params);
    const rows: T[] = [];

    try {
      while (statement.step()) {
        rows.push(mapper(statement.getAsObject()));
      }
    } finally {
      statement.free();
    }

    return rows;
  }
}

export const localDatabase = new LocalDatabase();
