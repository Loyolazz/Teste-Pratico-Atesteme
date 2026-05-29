import { apiRequest } from './apiClient';
import { localDatabase } from './localDatabase';
import type { Task, TaskPayload, TaskStatus } from '../types/api';
import { isNetworkError, logError, logWarning } from '../utils/errors';

export const taskService = {
  async list(projectId: number) {
    try {
      const tasks = await apiRequest<Task[]>(`/projects/${projectId}/tasks`);
      await localDatabase.saveTasks(projectId, tasks);
      return tasks;
    } catch (error) {
      const cachedTasks = await localDatabase.getTasks(projectId);
      if ((isNetworkError(error) || !navigator.onLine) && cachedTasks.length) {
        logWarning('task.list.cache_fallback', error, {
          projectId,
          cachedItems: cachedTasks.length
        });
        return cachedTasks;
      }

      logError('task.list.failed', error, { projectId });
      throw error;
    }
  },
  async create(projectId: number, payload: TaskPayload) {
    try {
      const task = await apiRequest<Task>(`/projects/${projectId}/tasks`, {
        method: 'POST',
        body: payload
      });
      await localDatabase.upsertTask(task);
      return task;
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('task.create.offline_queued', error, {
          projectId,
          taskTitle: payload.title
        });
        const task: Task = {
          id: -Date.now(),
          projectId,
          title: payload.title,
          description: payload.description ?? null,
          priority: payload.priority,
          status: payload.status,
          createdAt: new Date().toISOString()
        };
        await localDatabase.upsertTask(task);
        await localDatabase.addPendingOperation('CREATE_TASK', payload, { projectId, resourceId: task.id });
        return task;
      }

      logError('task.create.failed', error, {
        projectId,
        taskTitle: payload.title
      });
      throw error;
    }
  },
  async update(projectId: number, taskId: number, payload: TaskPayload) {
    try {
      const task = await apiRequest<Task>(`/projects/${projectId}/tasks/${taskId}`, {
        method: 'PUT',
        body: payload
      });
      await localDatabase.upsertTask(task);
      return task;
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('task.update.offline_queued', error, {
          projectId,
          taskId,
          taskTitle: payload.title
        });
        const cachedTask = await localDatabase.getTask(projectId, taskId);
        const task: Task = {
          id: taskId,
          projectId,
          title: payload.title,
          description: payload.description ?? null,
          priority: payload.priority,
          status: payload.status,
          createdAt: cachedTask?.createdAt ?? new Date().toISOString()
        };
        await localDatabase.upsertTask(task);
        await localDatabase.addPendingOperation('UPDATE_TASK', payload, { projectId, resourceId: taskId });
        return task;
      }

      logError('task.update.failed', error, {
        projectId,
        taskId,
        taskTitle: payload.title
      });
      throw error;
    }
  },
  async updateStatus(projectId: number, taskId: number, status: TaskStatus) {
    try {
      const task = await apiRequest<Task>(`/projects/${projectId}/tasks/${taskId}/status`, {
        method: 'PATCH',
        body: { status }
      });
      await localDatabase.upsertTask(task);
      return task;
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('task.status.offline_queued', error, {
          projectId,
          taskId,
          status
        });
        const cachedTask = await localDatabase.getTask(projectId, taskId);
        if (cachedTask) {
          const task = { ...cachedTask, status };
          await localDatabase.upsertTask(task);
          await localDatabase.addPendingOperation('UPDATE_TASK_STATUS', { status }, { projectId, resourceId: taskId });
          return task;
        }
      }

      logError('task.status.failed', error, {
        projectId,
        taskId,
        status
      });
      throw error;
    }
  },
  async remove(projectId: number, taskId: number) {
    try {
      await apiRequest<void>(`/projects/${projectId}/tasks/${taskId}`, {
        method: 'DELETE'
      });
      await localDatabase.deleteTask(taskId);
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('task.delete.offline_queued', error, {
          projectId,
          taskId
        });
        await localDatabase.deleteTask(taskId);
        if (taskId < 0) {
          await localDatabase.deletePendingOperationsForResource(taskId);
          return;
        }
        await localDatabase.addPendingOperation('DELETE_TASK', null, { projectId, resourceId: taskId });
        return;
      }

      logError('task.delete.failed', error, {
        projectId,
        taskId
      });
      throw error;
    }
  }
};
