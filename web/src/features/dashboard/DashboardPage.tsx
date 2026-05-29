import { FormEvent, useEffect, useMemo, useState } from 'react';
import { CheckCircle2, LogOut, Moon, Plus, Save, Sun, X } from 'lucide-react';
import { EmptyState } from '../../components/EmptyState';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import { showErrorAlert } from '../../services/errorAlertService';
import { notifyUser } from '../../services/notificationService';
import { ProjectList } from '../projects/ProjectList';
import { useProjects } from '../projects/useProjects';
import { TaskFilters } from '../tasks/TaskFilters';
import { TaskStatusBadge } from '../tasks/TaskStatusBadge';
import { useTasks } from '../tasks/useTasks';
import type { Project, Task, TaskPayload, TaskPriority, TaskStatus } from '../../types/api';
import { formatDate, toErrorMessage } from '../../utils/formatters';

const initialTaskForm: TaskPayload = {
  title: '',
  description: '',
  priority: 'MEDIA',
  status: 'PENDENTE'
};

export function DashboardPage() {
  const { user, logout } = useAuth();
  const { theme, toggleTheme } = useTheme();
  const { query: projectQuery, createProject, updateProject, deleteProject } = useProjects();
  const projects = projectQuery.data ?? [];
  const [selectedProjectId, setSelectedProjectId] = useState<number | null>(null);
  const selectedProject = projects.find((project) => project.id === selectedProjectId) ?? null;
  const { query: taskQuery, createTask, updateTask, updateTaskStatus, deleteTask } = useTasks(selectedProjectId);
  const tasks = taskQuery.data ?? [];

  const [projectForm, setProjectForm] = useState({ name: '', description: '' });
  const [editingProjectId, setEditingProjectId] = useState<number | null>(null);
  const [taskForm, setTaskForm] = useState<TaskPayload>(initialTaskForm);
  const [editingTaskId, setEditingTaskId] = useState<number | null>(null);
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
      description: project.description ?? ''
    });
  }

  function cancelProjectEdit() {
    setEditingProjectId(null);
    setProjectForm({ name: '', description: '' });
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
    setEditingTaskId(task.id);
    setTaskForm({
      title: task.title,
      description: task.description ?? '',
      priority: task.priority,
      status: task.status
    });
  }

  function cancelTaskEdit() {
    setEditingTaskId(null);
    setTaskForm(initialTaskForm);
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

      if (editingTaskId) {
        await updateTask.mutateAsync({ taskId: editingTaskId, payload: taskForm });
      } else {
        await createTask.mutateAsync(taskForm);
        void notifyUser('Tarefa criada', taskForm.title);
      }
      cancelTaskEdit();
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro na tarefa');
    }
  }

  async function handleTaskStatus(taskId: number, status: TaskStatus) {
    setError('');
    try {
      await updateTaskStatus.mutateAsync({ taskId, status });
      void notifyUser('Status atualizado', `Novo status: ${status}`);
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro ao atualizar status');
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

  return (
    <main className="app-shell">
      <header className="topbar">
        <div>
          <span className="eyebrow">Task Manager</span>
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
                  <select
                    value={taskForm.priority}
                    onChange={(event) => setTaskForm((current) => ({
                      ...current,
                      priority: event.target.value as TaskPriority
                    }))}
                  >
                    <option value="BAIXA">Baixa</option>
                    <option value="MEDIA">Média</option>
                    <option value="ALTA">Alta</option>
                  </select>
                  <select
                    value={taskForm.status}
                    onChange={(event) => setTaskForm((current) => ({
                      ...current,
                      status: event.target.value as TaskStatus
                    }))}
                  >
                    <option value="PENDENTE">Pendente</option>
                    <option value="EM_ANDAMENTO">Em andamento</option>
                    <option value="CONCLUIDA">Concluída</option>
                  </select>
                </div>
                <div className="form-actions">
                  <button className="primary-action" type="submit">
                    {editingTaskId ? <Save size={16} /> : <Plus size={16} />}
                    {editingTaskId ? 'Salvar tarefa' : 'Adicionar tarefa'}
                  </button>
                  {editingTaskId && (
                    <button className="secondary-action" type="button" onClick={cancelTaskEdit}>
                      <X size={16} aria-hidden="true" />
                      Cancelar
                    </button>
                  )}
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
                        <CheckCircle2 size={18} aria-hidden="true" />
                        <strong>{task.title}</strong>
                      </div>
                      {task.description && <p>{task.description}</p>}
                      <small>{task.priority} · {formatDate(task.createdAt)}</small>
                    </div>
                    <div className="task-controls">
                      <TaskStatusBadge status={task.status} />
                      <select
                        value={task.status}
                        onChange={(event) => handleTaskStatus(task.id, event.target.value as TaskStatus)}
                        title="Atualizar status"
                      >
                        <option value="PENDENTE">Pendente</option>
                        <option value="EM_ANDAMENTO">Em andamento</option>
                        <option value="CONCLUIDA">Concluída</option>
                      </select>
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
    </main>
  );
}
