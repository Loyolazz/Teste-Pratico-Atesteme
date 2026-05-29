import { SelectField, type SelectOption } from '../../components/SelectField';
import type { TaskPriority, TaskStatus } from '../../types/api';

const statusOptions: SelectOption<TaskStatus | 'ALL'>[] = [
  { value: 'ALL', label: 'Todos os status' },
  { value: 'PENDENTE', label: 'Pendente' },
  { value: 'EM_ANDAMENTO', label: 'Em andamento' },
  { value: 'CONCLUIDA', label: 'Concluída' }
];

const priorityOptions: SelectOption<TaskPriority | 'ALL'>[] = [
  { value: 'ALL', label: 'Todas as prioridades' },
  { value: 'BAIXA', label: 'Baixa' },
  { value: 'MEDIA', label: 'Média' },
  { value: 'ALTA', label: 'Alta' }
];

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
      <SelectField
        label="Status"
        value={statusFilter}
        options={statusOptions}
        onChange={onStatusChange}
      />
      <SelectField
        label="Prioridade"
        value={priorityFilter}
        options={priorityOptions}
        onChange={onPriorityChange}
      />
    </div>
  );
}
