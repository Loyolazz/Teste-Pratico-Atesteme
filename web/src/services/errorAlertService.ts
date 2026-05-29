import { toErrorMessage } from '../utils/errors';

export type ErrorAlert = {
  id: number;
  message: string;
  title?: string;
};

type ErrorAlertListener = (alert: ErrorAlert) => void;

const listeners = new Set<ErrorAlertListener>();
let nextAlertId = 1;

export function subscribeToErrorAlerts(listener: ErrorAlertListener) {
  listeners.add(listener);
  return () => {
    listeners.delete(listener);
  };
}

export function showErrorAlert(error: unknown, title = 'Erro') {
  const message = typeof error === 'string' ? error : toErrorMessage(error);

  if (!message.trim()) {
    return;
  }

  const alert = {
    id: nextAlertId,
    title,
    message
  };

  nextAlertId += 1;
  listeners.forEach((listener) => listener(alert));
}
