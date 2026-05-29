import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { projectService } from '../../services/projectService';
import type { ProjectPayload } from '../../types/api';

export function useProjects() {
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: ['projects'],
    queryFn: projectService.list
  });

  const createProject = useMutation({
    mutationFn: (payload: ProjectPayload) => projectService.create(payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['projects'] })
  });

  const updateProject = useMutation({
    mutationFn: ({ projectId, payload }: { projectId: number; payload: ProjectPayload }) =>
      projectService.update(projectId, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['projects'] })
  });

  const deleteProject = useMutation({
    mutationFn: (projectId: number) => projectService.remove(projectId),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['projects'] })
  });

  return {
    query,
    createProject,
    updateProject,
    deleteProject
  };
}

