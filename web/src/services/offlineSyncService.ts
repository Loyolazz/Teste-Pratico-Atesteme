import { apiRequest } from './apiClient';
import { localDatabase, type PendingOperation } from './localDatabase';
import type { Project, Task } from '../types/api';
import { logError, logInfo, logWarning } from '../utils/errors';

let isSyncing = false;

export async function syncPendingOperations() {
  if (isSyncing || !navigator.onLine) {
    return;
  }

  isSyncing = true;

  try {
    let operations = await localDatabase.getPendingOperations();
    if (operations.length) {
      logInfo('offline_sync.started', { pendingOperations: operations.length });
    }

    while (operations.length) {
      const operation = operations[0];
      const synced = await syncOperation(operation).catch((error: unknown) => resolveSyncError(operation, error));
      if (!synced) {
        logWarning('offline_sync.paused', null, {
          operationId: operation.id,
          operationType: operation.operationType,
          resourceId: operation.resourceId,
          projectId: operation.projectId
        });
        break;
      }

      await localDatabase.deletePendingOperation(operation.id);
      operations = await localDatabase.getPendingOperations();
    }
    if (!operations.length) {
      logInfo('offline_sync.finished');
    }
  } finally {
    isSyncing = false;
  }
}

async function syncOperation(operation: PendingOperation) {
  switch (operation.operationType) {
    case 'CREATE_PROJECT': {
      const project = await apiRequest<Project>('/projects', {
        method: 'POST',
        body: operation.payload
      });
      if (operation.resourceId && operation.resourceId < 0) {
        await localDatabase.replaceProjectReferences(operation.resourceId, project.id);
        await localDatabase.deleteProject(operation.resourceId);
      }
      await localDatabase.upsertProject(project);
      return true;
    }
    case 'UPDATE_PROJECT':
      await apiRequest<Project>(`/projects/${operation.resourceId}`, {
        method: 'PUT',
        body: operation.payload
      });
      return true;
    case 'DELETE_PROJECT':
      if (operation.resourceId && operation.resourceId > 0) {
        await apiRequest<void>(`/projects/${operation.resourceId}`, { method: 'DELETE' });
      }
      return true;
    case 'CREATE_TASK': {
      const task = await apiRequest<Task>(`/projects/${operation.projectId}/tasks`, {
        method: 'POST',
        body: operation.payload
      });
      if (operation.resourceId && operation.resourceId < 0) {
        await localDatabase.deleteTask(operation.resourceId);
      }
      await localDatabase.upsertTask(task);
      return true;
    }
    case 'UPDATE_TASK':
      await apiRequest<Task>(`/projects/${operation.projectId}/tasks/${operation.resourceId}`, {
        method: 'PUT',
        body: operation.payload
      });
      return true;
    case 'UPDATE_TASK_STATUS':
      await apiRequest<Task>(`/projects/${operation.projectId}/tasks/${operation.resourceId}/status`, {
        method: 'PATCH',
        body: operation.payload
      });
      return true;
    case 'DELETE_TASK':
      if (operation.resourceId && operation.resourceId > 0) {
        await apiRequest<void>(`/projects/${operation.projectId}/tasks/${operation.resourceId}`, { method: 'DELETE' });
      }
      return true;
    default:
      return true;
  }
}

async function resolveSyncError(operation: PendingOperation, error: unknown) {
  if (statusFromError(error) !== 404) {
    logError('offline_sync.operation_failed', error, {
      operationId: operation.id,
      operationType: operation.operationType,
      resourceId: operation.resourceId,
      projectId: operation.projectId
    });
    return false;
  }

  logWarning('offline_sync.conflict_resolved_not_found', error, {
    operationId: operation.id,
    operationType: operation.operationType,
    resourceId: operation.resourceId,
    projectId: operation.projectId
  });

  switch (operation.operationType) {
    case 'UPDATE_PROJECT':
    case 'DELETE_PROJECT':
      if (operation.resourceId) {
        await localDatabase.deleteProject(operation.resourceId);
      }
      return true;
    case 'CREATE_TASK':
    case 'UPDATE_TASK':
    case 'UPDATE_TASK_STATUS':
    case 'DELETE_TASK':
      if (operation.resourceId) {
        await localDatabase.deleteTask(operation.resourceId);
      }
      return true;
    default:
      return false;
  }
}

function statusFromError(error: unknown) {
  if (typeof error === 'object' && error !== null && 'status' in error) {
    const status = Number((error as { status?: number }).status);
    return Number.isNaN(status) ? null : status;
  }

  return null;
}
