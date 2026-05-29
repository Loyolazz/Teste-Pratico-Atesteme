import { KeyboardEvent, useMemo, useState } from 'react';
import { Plus, X } from 'lucide-react';
import { SelectField, type SelectOption } from '../../components/SelectField';
import type { AssignableUser } from '../../types/api';

type ProjectWorkersEditorProps = {
  workers: string[];
  users: AssignableUser[];
  onChange: (workers: string[]) => void;
};

export function ProjectWorkersEditor({
  workers,
  users,
  onChange
}: ProjectWorkersEditorProps) {
  const [manualName, setManualName] = useState('');
  const [selectedUserId, setSelectedUserId] = useState('');

  const userOptions = useMemo<SelectOption<string>[]>(() => [
    { value: '', label: 'Usuário cadastrado' },
    ...users.map((user) => ({
      value: String(user.id),
      label: `${user.name} · ${user.email}`
    }))
  ], [users]);

  function addWorker(name: string) {
    const normalizedName = name.trim();
    if (!normalizedName || workers.includes(normalizedName)) {
      return;
    }

    onChange([...workers, normalizedName]);
  }

  function addManualWorker() {
    addWorker(manualName);
    setManualName('');
  }

  function handleRegisteredUser(userId: string) {
    setSelectedUserId(userId);
    const user = users.find((item) => String(item.id) === userId);
    if (user) {
      addWorker(user.name);
      setSelectedUserId('');
    }
  }

  function removeWorker(worker: string) {
    onChange(workers.filter((item) => item !== worker));
  }

  function handleManualKeyDown(event: KeyboardEvent<HTMLInputElement>) {
    if (event.key === 'Enter') {
      event.preventDefault();
      addManualWorker();
    }
  }

  return (
    <div className="workers-editor">
      <span className="field-label">Equipe no projeto</span>
      <div className="worker-controls">
        <SelectField
          label="Cadastrados"
          value={selectedUserId}
          options={userOptions}
          onChange={handleRegisteredUser}
        />
        <label className="input-with-action">
          <span>Nome externo</span>
          <div>
            <input
              placeholder="Adicionar pessoa"
              value={manualName}
              onChange={(event) => setManualName(event.target.value)}
              onKeyDown={handleManualKeyDown}
            />
            <button type="button" onClick={addManualWorker} title="Adicionar pessoa">
              <Plus size={16} aria-hidden="true" />
            </button>
          </div>
        </label>
      </div>

      <div className="worker-chips" aria-live="polite">
        {workers.length ? workers.map((worker) => (
          <span className="worker-chip" key={worker}>
            {worker}
            <button type="button" onClick={() => removeWorker(worker)} title={`Remover ${worker}`}>
              <X size={14} aria-hidden="true" />
            </button>
          </span>
        )) : <small>Ninguém informado ainda.</small>}
      </div>
    </div>
  );
}
