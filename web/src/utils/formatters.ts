import { toErrorMessage as formatErrorMessage } from './errors';

export function formatDate(value: string) {
  return new Intl.DateTimeFormat('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric'
  }).format(new Date(value));
}

export function toErrorMessage(error: unknown) {
  return formatErrorMessage(error);
}
