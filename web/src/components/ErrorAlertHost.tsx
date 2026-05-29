import { AlertTriangle, X } from 'lucide-react';
import { useEffect, useState } from 'react';
import { type ErrorAlert, subscribeToErrorAlerts } from '../services/errorAlertService';

const ALERT_DURATION_MS = 7000;

export function ErrorAlertHost() {
  const [alerts, setAlerts] = useState<ErrorAlert[]>([]);

  useEffect(() => {
    return subscribeToErrorAlerts((alert) => {
      setAlerts((current) => [...current, alert].slice(-3));
      window.setTimeout(() => {
        setAlerts((current) => current.filter((item) => item.id !== alert.id));
      }, ALERT_DURATION_MS);
    });
  }, []);

  if (!alerts.length) {
    return null;
  }

  return (
    <div className="error-alert-region" aria-live="assertive" aria-label="Alertas de erro">
      {alerts.map((alert) => (
        <div className="error-alert" role="alert" key={alert.id}>
          <AlertTriangle size={20} aria-hidden="true" />
          <div>
            {alert.title && <strong>{alert.title}</strong>}
            <p>{alert.message}</p>
          </div>
          <button
            type="button"
            aria-label="Fechar alerta"
            onClick={() => setAlerts((current) => current.filter((item) => item.id !== alert.id))}
          >
            <X size={18} aria-hidden="true" />
          </button>
        </div>
      ))}
    </div>
  );
}
