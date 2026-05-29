import { FormEvent, useEffect, useMemo, useState } from 'react';
import { LogOut, Moon, Plus, Save, Sun, X } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { EmptyState } from '../../components/EmptyState';
import { SelectField, type SelectOption } from '../../components/SelectField';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import { showErrorAlert } from '../../services/errorAlertService';
import { notifyUser } from '../../services/notificationService';
import { userService } from '../../services/userService';
import { ProjectList } from '../projects/ProjectList';
import { ProjectWorkersEditor } from '../projects/ProjectWorkersEditor';
import { useProjects } from '../projects/useProjects';
import { TaskFilters } from '../tasks/TaskFilters';
import { TaskPriorityBadge } from '../tasks/TaskPriorityBadge';
import { TaskEditModal } from '../tasks/TaskEditModal';
import { TaskStatusBadge, TaskStatusIcon } from '../tasks/TaskStatusBadge';
import { useTasks } from '../tasks/useTasks';
import type { Project, Task, TaskPayload, TaskPriority, TaskStatus } from '../../types/api';
import { formatDate, toErrorMessage } from '../../utils/formatters';

const initialTaskForm: TaskPayload = {
  title: '',
  description: '',
  priority: 'MEDIA',
  status: 'PENDENTE'
};

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

export function DashboardPage() {
  const { user, logout } = useAuth();
  const { appName, theme, toggleTheme } = useTheme();
  const { query: projectQuery, createProject, updateProject, deleteProject } = useProjects();
  const userQuery = useQuery({
    queryKey: ['assignable-users'],
    queryFn: userService.listAssignable
  });
  const projects = projectQuery.data ?? [];
  const assignableUsers = userQuery.data ?? [];
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);
  const selectedProject = projects.find((project) => project.id === selectedProjectId) ?? null;
  const { query: taskQuery, createTask, updateTask, deleteTask } = useTasks(selectedProjectId);
  const tasks = taskQuery.data ?? [];

  const [projectForm, setProjectForm] = useState({ name: '', description: '', workers: [] as string[] });
  const [editingProjectId, setEditingProjectId] = useState<number | null>(null);
  const [taskForm, setTaskForm] = useState<TaskPayload>(initialTaskForm);
  const [editingTask, setEditingTask] = useState<Task | null>(null);
  const [editingTaskForm, setEditingTaskForm] = useState<TaskPayload>(initialTaskForm);
  const [statusFilter, setStatusFilter] = useState<TaskStatus | 'ALL'>('ALL');
  const [priorityFilter, setPriorityFilter] = useState<TaskPriority | 'ALL'>('ALL');
  const [error, setError] = useState('');
  const queryError = projectQuery.isError
    ? toErrorMessage(projectQuery.error)
    : taskQuery.isError
      ? toErrorMessage(taskQuery.error)
      : '';

  useEffect(() => {
    if (!projects.length) {
      setSelectedProjectId(null);
      return;
    }

    if (!selectedProjectId || !projects.some((project) => project.id === selectedProjectId)) {
      setSelectedProjectId(projects[0].id);
    }
  }, [projects, selectedProjectId]);

  const filteredTasks = useMemo(() => {
    return tasks.filter((task) => {
      const matchesStatus = statusFilter === 'ALL' || task.status === statusFilter;
      const matchesPriority = priorityFilter === 'ALL' || task.priority === priorityFilter;
      return matchesStatus && matchesPriority;
    });
  }, [priorityFilter, statusFilter, tasks]);

  const indicators = useMemo(() => ({
    total: tasks.length,
    pending: tasks.filter((task) => task.status === 'PENDENTE').length,
    done: tasks.filter((task) => task.status === 'CONCLUIDA').length
  }), [tasks]);

  function startProjectEdit(project: Project) {
    setEditingProjectId(project.id);
    setProjectForm({
      name: project.name,
      description: project.description ?? '',
      workers: project.workers ?? []
    });
  }

  function cancelProjectEdit() {
    setEditingProjectId(null);
    setProjectForm({ name: '', description: '', workers: [] });
  }

  async function handleProjectSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');

    try {
      if (!projectForm.name.trim()) {
        throw new Error('Informe o nome do projeto.');
      }

      if (editingProjectId) {
        await updateProject.mutateAsync({ projectId: editingProjectId, payload: projectForm });
      } else {
        const project = await createProject.mutateAsync(projectForm);
        setSelectedProjectId(project.id);
      }
      cancelProjectEdit();
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro no projeto');
    }
  }

  async function handleProjectDelete(projectId: number) {
    if (!window.confirm('Excluir este projeto e suas tarefas?')) {
      return;
    }

    setError('');
    try {
      await deleteProject.mutateAsync(projectId);
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro ao excluir projeto');
    }
  }

  function startTaskEdit(task: Task) {
    setEditingTask(task);
    setEditingTaskForm({
      title: task.title,
      description: task.description ?? '',
      priority: task.priority,
      status: task.status
    });
  }

  function cancelTaskEdit() {
    setEditingTask(null);
    setEditingTaskForm(initialTaskForm);
  }

  async function handleTaskSubmit(event: FormEvent) {
    event.preventDefault();

    if (!selectedProjectId) {
      const message = 'Selecione um projeto antes de criar tarefas.';
      setError(message);
      showErrorAlert(message, 'Erro na tarefa');
      return;
    }

    setError('');
    try {
      if (!taskForm.title.trim()) {
        throw new Error('Informe o título da tarefa.');
      }

      await createTask.mutateAsync(taskForm);
      void notifyUser('Tarefa criada', taskForm.title);
      setTaskForm(initialTaskForm);
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro na tarefa');
    }
  }

  async function handleTaskDelete(taskId: number) {
    if (!window.confirm('Excluir esta tarefa?')) {
      return;
    }

    setError('');
    try {
      await deleteTask.mutateAsync(taskId);
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro ao excluir tarefa');
    }
  }

  async function handleTaskEditSubmit(event: FormEvent) {
    event.preventDefault();

    if (!editingTask) {
      return;
    }

    setError('');
    try {
      if (!editingTaskForm.title.trim()) {
        throw new Error('Informe o título da tarefa.');
      }

      await updateTask.mutateAsync({ taskId: editingTask.id, payload: editingTaskForm });
      void notifyUser('Tarefa editada', editingTaskForm.title);
      cancelTaskEdit();
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro na tarefa');
    }
  }

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <span className="eyebrow">{appName}</span>
          <h1>Olá, {user?.name}</h1>
        </div>
        <div className="topbar-actions">
          <button className="icon-text-button" type="button" onClick={toggleTheme}>
            {theme === 'dark' ? <Sun size={18} aria-hidden="true" /> : <Moon size={18} aria-hidden="true" />}
            Tema
          </button>
          <button className="icon-text-button" type="button" onClick={logout}>
            <LogOut size={18} aria-hidden="true" />
            Sair
          </button>
        </div>
      </header>

      {(error || queryError) && <p className="global-error">{error || queryError}</p>}

      <section className="dashboard-grid">
        <aside className="panel projects-panel">
          <div className="panel-heading">
            <div>
              <span className="eyebrow">Projetos</span>
              <h2>{projects.length} cadastrados</h2>
            </div>
          </div>

          <form className="compact-form" onSubmit={handleProjectSubmit}>
            <input
              placeholder="Nome do projeto"
              value={projectForm.name}
              onChange={(event) => setProjectForm((current) => ({ ...current, name: event.target.value }))}
              required
            />
            <textarea
              placeholder="Descrição"
              value={projectForm.description}
              onChange={(event) => setProjectForm((current) => ({ ...current, description: event.target.value }))}
            />
            <ProjectWorkersEditor
              workers={projectForm.workers}
              users={assignableUsers}
              onChange={(workers) => setProjectForm((current) => ({ ...current, workers }))}
            />
            <div className="form-actions">
              <button className="primary-action" type="submit">
                {editingProjectId ? <Save size={16} /> : <Plus size={16} />}
                {editingProjectId ? 'Salvar' : 'Novo'}
              </button>
              {editingProjectId && (
                <button className="secondary-action" type="button" onClick={cancelProjectEdit}>
                  <X size={16} aria-hidden="true" />
                  Cancelar
                </button>
              )}
            </div>
          </form>

          {projectQuery.isLoading && <p className="muted">Carregando projetos...</p>}
          {!projectQuery.isLoading && !projects.length && (
            <EmptyState title="Nenhum projeto" description="Crie um projeto para organizar tarefas." />
          )}
          <ProjectList
            projects={projects}
            selectedProjectId={selectedProjectId}
            onSelect={setSelectedProjectId}
            onEdit={startProjectEdit}
            onDelete={handleProjectDelete}
          />
        </aside>

        <section className="panel tasks-panel">
          <div className="panel-heading">
            <div>
              <span className="eyebrow">{selectedProject?.name ?? 'Tarefas'}</span>
              <h2>{selectedProject ? selectedProject.description || 'Sem descrição' : 'Selecione um projeto'}</h2>
            </div>
          </div>

          <div className="indicator-grid">
            <div>
              <strong>{indicators.total}</strong>
              <span>Total</span>
            </div>
            <div>
              <strong>{indicators.pending}</strong>
              <span>Pendentes</span>
            </div>
            <div>
              <strong>{indicators.done}</strong>
              <span>Concluídas</span>
            </div>
          </div>

          {selectedProject && (
            <div className="project-team">
              <span className="field-label">Trabalhando agora</span>
              <div className="worker-chips">
                {selectedProject.workers?.length ? selectedProject.workers.map((worker) => (
                  <span className="worker-chip" key={worker}>{worker}</span>
                )) : <small>Ninguém informado ainda.</small>}
              </div>
            </div>
          )}

          {selectedProject ? (
            <>
              <form className="task-form" onSubmit={handleTaskSubmit}>
                <input
                  placeholder="Título da tarefa"
                  value={taskForm.title}
                  onChange={(event) => setTaskForm((current) => ({ ...current, title: event.target.value }))}
                  required
                />
                <textarea
                  placeholder="Descrição"
                  value={taskForm.description}
                  onChange={(event) => setTaskForm((current) => ({ ...current, description: event.target.value }))}
                />
                <div className="form-row">
                  <SelectField
                    label="Prioridade"
                    value={taskForm.priority}
                    options={priorityOptions}
                    onChange={(priority) => setTaskForm((current) => ({ ...current, priority }))}
                  />
                  <SelectField
                    label="Status"
                    value={taskForm.status}
                    options={statusOptions}
                    onChange={(status) => setTaskForm((current) => ({ ...current, status }))}
                  />
                </div>
                <div className="form-actions">
                  <button className="primary-action" type="submit">
                    <Plus size={16} />
                    Adicionar tarefa
                  </button>
                </div>
              </form>

              <TaskFilters
                statusFilter={statusFilter}
                priorityFilter={priorityFilter}
                onStatusChange={setStatusFilter}
                onPriorityChange={setPriorityFilter}
              />

              {taskQuery.isLoading && <p className="muted">Carregando tarefas...</p>}
              {!taskQuery.isLoading && !filteredTasks.length && (
                <EmptyState title="Nenhuma tarefa" description="Ajuste os filtros ou adicione uma nova tarefa." />
              )}

              <div className="task-list">
                {filteredTasks.map((task) => (
                  <article className="task-item" key={task.id}>
                    <div>
                      <div className="task-title">
                        <TaskStatusIcon status={task.status} />
                        <strong>{task.title}</strong>
                      </div>
                      {task.description && <p>{task.description}</p>}
                      <div className="task-meta">
                        <TaskPriorityBadge priority={task.priority} />
                        <small>{formatDate(task.createdAt)}</small>
                      </div>
                    </div>
                    <div className="task-controls">
                      <TaskStatusBadge status={task.status} />
                      <button type="button" onClick={() => startTaskEdit(task)}>Editar</button>
                      <button type="button" onClick={() => handleTaskDelete(task.id)}>Excluir</button>
                    </div>
                  </article>
                ))}
              </div>
            </>
          ) : (
            <EmptyState title="Sem projeto selecionado" description="Crie ou escolha um projeto para ver tarefas." />
          )}
        </section>
      </section>

      {editingTask && (
        <TaskEditModal
          form={editingTaskForm}
          isSaving={updateTask.isPending}
          onChange={setEditingTaskForm}
          onClose={cancelTaskEdit}
          onSubmit={handleTaskEditSubmit}
        />
      )}
    </main>
  );
}
