import { FormEvent, useEffect } from 'react';
import { Save, X } from 'lucide-react';
import { SelectField, type SelectOption } from '../../components/SelectField';
import type { TaskPayload, TaskPriority, TaskStatus } from '../../types/api';

const priorityOptions: SelectOption<TaskPriority>[] = [
  { value: 'BAIXA', label: 'Baixa' },
  { value: 'MEDIA', label: 'Média' },
  { value: 'ALTA', label: 'Alta' }
];

const statusOptions: SelectOption<TaskStatus>[] = [
  { value: 'PENDENTE', label: 'Pendente' },
  { value: 'EM_ANDAMENTO', label: 'Em andamento' },
  { value: 'CONCLUIDA', label: 'Concluída' }
];

type TaskEditModalProps = {
  form: TaskPayload;
  isSaving: boolean;
  onChange: (form: TaskPayload) => void;
  onClose: () => void;
  onSubmit: (event: FormEvent) => void;
};

export function TaskEditModal({
  form,
  isSaving,
  onChange,
  onClose,
  onSubmit
}: TaskEditModalProps) {
  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === 'Escape') {
        onClose();
      }
    }

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onClose]);

  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={onClose}>
      <section
        aria-modal="true"
        className="modal-panel"
        role="dialog"
        aria-labelledby="task-edit-title"
        onMouseDown={(event) => event.stopPropagation()}
      >
        <div className="modal-heading">
          <div>
            <span className="eyebrow">Tarefa</span>
            <h2 id="task-edit-title">Editar tarefa</h2>
          </div>
          <button className="modal-close" type="button" onClick={onClose} title="Fechar">
            <X size={18} aria-hidden="true" />
          </button>
        </div>

        <form className="task-form" onSubmit={onSubmit}>
          <input
            placeholder="Título da tarefa"
            value={form.title}
            onChange={(event) => onChange({ ...form, title: event.target.value })}
            required
          />
          <textarea
            placeholder="Descrição"
            value={form.description ?? ''}
            onChange={(event) => onChange({ ...form, description: event.target.value })}
          />
          <div className="form-row">
            <SelectField
              label="Prioridade"
              value={form.priority}
              options={priorityOptions}
              onChange={(priority) => onChange({ ...form, priority })}
            />
            <SelectField
              label="Status"
              value={form.status}
              options={statusOptions}
              onChange={(status) => onChange({ ...form, status })}
            />
          </div>
          <div className="form-actions">
            <button className="primary-action" type="submit" disabled={isSaving}>
              <Save size={16} aria-hidden="true" />
              {isSaving ? 'Salvando...' : 'Salvar tarefa'}
            </button>
            <button className="secondary-action" type="button" onClick={onClose}>
              <X size={16} aria-hidden="true" />
              Cancelar
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
