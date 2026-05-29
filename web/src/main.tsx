import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import { App } from './App';
import { queryClient } from './app/queryClient';
import { ErrorAlertHost } from './components/ErrorAlertHost';
import { ErrorBoundary } from './components/ErrorBoundary';
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { showErrorAlert } from './services/errorAlertService';
import { syncPendingOperations } from './services/offlineSyncService';
import { logError } from './utils/errors';
import './styles.css';

window.addEventListener('online', () => {
  void syncPendingOperations().catch((error) => {
    logError('offline_sync.online_event_failed', error);
    showErrorAlert(error, 'Falha ao sincronizar');
  });
});

window.addEventListener('error', (event) => {
  logError('window.error', event.error ?? event.message, {
    filename: event.filename,
    line: event.lineno,
    column: event.colno
  });
  showErrorAlert('Ocorreu um erro inesperado na tela. Recarregue a página se o problema continuar.', 'Erro inesperado');
});

window.addEventListener('unhandledrejection', (event) => {
  logError('window.unhandled_rejection', event.reason);
  showErrorAlert(event.reason, 'Erro inesperado');
});

void syncPendingOperations().catch((error) => {
  logError('offline_sync.initial_failed', error);
  showErrorAlert(error, 'Falha ao sincronizar');
});

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <ThemeProvider>
            <AuthProvider>
              <ErrorAlertHost />
              <App />
            </AuthProvider>
          </ThemeProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);
