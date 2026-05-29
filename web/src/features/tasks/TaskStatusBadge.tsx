import type { TaskStatus } from '../../types/api';

const statusLabel: Record<TaskStatus, string> = {
  PENDENTE: 'Pendente',
  EM_ANDAMENTO: 'Em andamento',
  CONCLUIDA: 'Concluída'
};

export function TaskStatusBadge({ status }: { status: TaskStatus }) {
  return <span className={`status-badge ${status.toLowerCase()}`}>{statusLabel[status]}</span>;
}

