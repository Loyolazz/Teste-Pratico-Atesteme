import { Edit2, Folder, Trash2 } from 'lucide-react';
import type { Project } from '../../types/api';
import { formatDate } from '../../utils/formatters';

type ProjectListProps = {
  projects: Project[];
  selectedProjectId: number | null;
  onSelect: (projectId: number) => void;
  onEdit: (project: Project) => void;
  onDelete: (projectId: number) => void;
};

export function ProjectList({
  projects,
  selectedProjectId,
  onSelect,
  onEdit,
  onDelete
}: ProjectListProps) {
  return (
    <div className="list">
      {projects.map((project) => (
        <article
          className={`project-item ${selectedProjectId === project.id ? 'is-selected' : ''}`}
          key={project.id}
        >
          <button className="project-main" type="button" onClick={() => onSelect(project.id)}>
            <Folder size={18} aria-hidden="true" />
            <span>
              <strong>{project.name}</strong>
              <small>{project.taskCount} tarefas · {formatDate(project.createdAt)}</small>
            </span>
          </button>
          <div className="item-actions">
            <button type="button" title="Editar projeto" onClick={() => onEdit(project)}>
              <Edit2 size={16} aria-hidden="true" />
            </button>
            <button type="button" title="Excluir projeto" onClick={() => onDelete(project.id)}>
              <Trash2 size={16} aria-hidden="true" />
            </button>
          </div>
        </article>
      ))}
    </div>
  );
}

