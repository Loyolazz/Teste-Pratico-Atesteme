import { CheckCircle2, CircleDashed, LoaderCircle } from 'lucide-react';
import type { TaskStatus } from '../../types/api';

const statusLabel: Record<TaskStatus, string> = {
  PENDENTE: 'Pendente',
  EM_ANDAMENTO: 'Em andamento',
  CONCLUIDA: 'Concluída'
};

const statusIcon = {
  PENDENTE: CircleDashed,
  EM_ANDAMENTO: LoaderCircle,
  CONCLUIDA: CheckCircle2
};

export function TaskStatusIcon({ status }: { status: TaskStatus }) {
  const Icon = statusIcon[status];
  return <Icon className={`status-icon ${status.toLowerCase()}`} size={18} aria-hidden="true" />;
}

export function TaskStatusBadge({ status }: { status: TaskStatus }) {
  const Icon = statusIcon[status];

  return (
    <span className={`status-badge ${status.toLowerCase()}`}>
      <Icon size={14} aria-hidden="true" />
      {statusLabel[status]}
    </span>
  );
}
