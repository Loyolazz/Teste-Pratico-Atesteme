import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { taskService } from '../../services/taskService';
import type { TaskPayload, TaskStatus } from '../../types/api';

export function useTasks(projectId: number | null) {
  const queryClient = useQueryClient();
  const tasksKey = ['tasks', projectId];

  const query = useQuery({
    queryKey: tasksKey,
    queryFn: () => taskService.list(projectId as number),
    enabled: Boolean(projectId)
  });

  const createTask = useMutation({
    mutationFn: (payload: TaskPayload) => taskService.create(projectId as number, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: tasksKey });
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    }
  });

  const updateTask = useMutation({
    mutationFn: ({ taskId, payload }: { taskId: number; payload: TaskPayload }) =>
      taskService.update(projectId as number, taskId, payload),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: tasksKey })
  });

  const updateTaskStatus = useMutation({
    mutationFn: ({ taskId, status }: { taskId: number; status: TaskStatus }) =>
      taskService.updateStatus(projectId as number, taskId, status),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: tasksKey })
  });

  const deleteTask = useMutation({
    mutationFn: (taskId: number) => taskService.remove(projectId as number, taskId),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: tasksKey });
      queryClient.invalidateQueries({ queryKey: ['projects'] });
    }
  });

  return {
    query,
    createTask,
    updateTask,
    updateTaskStatus,
    deleteTask
  };
}

