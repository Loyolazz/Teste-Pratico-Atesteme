import { apiRequest } from './apiClient';
import { localDatabase } from './localDatabase';
import type { Project, ProjectPayload } from '../types/api';
import { isNetworkError, logError, logWarning } from '../utils/errors';

export const projectService = {
  async list() {
    try {
      const projects = await apiRequest<Project[]>('/projects');
      await localDatabase.saveProjects(projects);
      return projects;
    } catch (error) {
      const cachedProjects = await localDatabase.getProjects();
      if ((isNetworkError(error) || !navigator.onLine) && cachedProjects.length) {
        logWarning('project.list.cache_fallback', error, {
          cachedItems: cachedProjects.length
        });
        return cachedProjects;
      }

      logError('project.list.failed', error);
      throw error;
    }
  },
  async create(payload: ProjectPayload) {
    try {
      const project = await apiRequest<Project>('/projects', {
        method: 'POST',
        body: payload
      });
      await localDatabase.upsertProject(project);
      return project;
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('project.create.offline_queued', error, {
          projectName: payload.name
        });
        const localProject: Project = {
          id: -Date.now(),
          name: payload.name,
          description: payload.description ?? null,
          createdAt: new Date().toISOString(),
          taskCount: 0
        };
        await localDatabase.upsertProject(localProject);
        await localDatabase.addPendingOperation('CREATE_PROJECT', payload, { resourceId: localProject.id });
        return localProject;
      }

      logError('project.create.failed', error, {
        projectName: payload.name
      });
      throw error;
    }
  },
  async update(projectId: number, payload: ProjectPayload) {
    try {
      const project = await apiRequest<Project>(`/projects/${projectId}`, {
        method: 'PUT',
        body: payload
      });
      await localDatabase.upsertProject(project);
      return project;
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('project.update.offline_queued', error, {
          projectId,
          projectName: payload.name
        });
        const cachedProject = await localDatabase.getProject(projectId);
        const project: Project = {
          id: projectId,
          name: payload.name,
          description: payload.description ?? null,
          createdAt: cachedProject?.createdAt ?? new Date().toISOString(),
          taskCount: cachedProject?.taskCount ?? 0
        };
        await localDatabase.upsertProject(project);
        await localDatabase.addPendingOperation('UPDATE_PROJECT', payload, { resourceId: projectId });
        return project;
      }

      logError('project.update.failed', error, {
        projectId,
        projectName: payload.name
      });
      throw error;
    }
  },
  async remove(projectId: number) {
    try {
      await apiRequest<void>(`/projects/${projectId}`, {
        method: 'DELETE'
      });
      await localDatabase.deleteProject(projectId);
    } catch (error) {
      if (isNetworkError(error) || !navigator.onLine) {
        logWarning('project.delete.offline_queued', error, { projectId });
        await localDatabase.deleteProject(projectId);
        if (projectId < 0) {
          await localDatabase.deletePendingOperationsForProject(projectId);
          return;
        }
        await localDatabase.addPendingOperation('DELETE_PROJECT', null, { resourceId: projectId });
        return;
      }

      logError('project.delete.failed', error, { projectId });
      throw error;
    }
  }
};
