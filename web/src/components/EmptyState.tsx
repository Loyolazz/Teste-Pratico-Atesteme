import { ClipboardList } from 'lucide-react';

type EmptyStateProps = {
  title: string;
  description: string;
};

export function EmptyState({ title, description }: EmptyStateProps) {
  return (
    <div className="empty-state">
      <ClipboardList size={32} aria-hidden="true" />
      <strong>{title}</strong>
      <span>{description}</span>
    </div>
  );
}

