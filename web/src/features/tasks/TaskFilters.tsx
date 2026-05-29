import type { TaskPriority, TaskStatus } from '../../types/api';

type TaskFiltersProps = {
  statusFilter: TaskStatus | 'ALL';
  priorityFilter: TaskPriority | 'ALL';
  onStatusChange: (status: TaskStatus | 'ALL') => void;
  onPriorityChange: (priority: TaskPriority | 'ALL') => void;
};

export function TaskFilters({
  statusFilter,
  priorityFilter,
  onStatusChange,
  onPriorityChange
}: TaskFiltersProps) {
  return (
    <div className="filters">
      <select value={statusFilter} onChange={(event) => onStatusChange(event.target.value as TaskStatus | 'ALL')}>
        <option value="ALL">Todos os status</option>
        <option value="PENDENTE">Pendente</option>
        <option value="EM_ANDAMENTO">Em andamento</option>
        <option value="CONCLUIDA">Concluída</option>
      </select>

      <select
        value={priorityFilter}
        onChange={(event) => onPriorityChange(event.target.value as TaskPriority | 'ALL')}
      >
        <option value="ALL">Todas as prioridades</option>
        <option value="BAIXA">Baixa</option>
        <option value="MEDIA">Média</option>
        <option value="ALTA">Alta</option>
      </select>
    </div>
  );
}

