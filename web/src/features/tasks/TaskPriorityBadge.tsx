import type { TaskPriority } from '../../types/api';

const priorityLabel: Record<TaskPriority, string> = {
  BAIXA: 'Baixa',
  MEDIA: 'Média',
  ALTA: 'Alta'
};

export function TaskPriorityBadge({ priority }: { priority: TaskPriority }) {
  return (
    <span className={`priority-badge ${priority.toLowerCase()}`}>
      {priorityLabel[priority]}
    </span>
  );
}
