import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import { App } from './App';
import { queryClient } from './app/queryClient';
import { ErrorBoundary } from './components/ErrorBoundary';
import { AuthProvider } from './context/AuthContext';
import { ThemeProvider } from './context/ThemeContext';
import { syncPendingOperations } from './services/offlineSyncService';
import { logError } from './utils/errors';
import './styles.css';

window.addEventListener('online', () => {
  void syncPendingOperations().catch((error) => logError('offline_sync.online_event_failed', error));
});

window.addEventListener('error', (event) => {
  logError('window.error', event.error ?? event.message, {
    filename: event.filename,
    line: event.lineno,
    column: event.colno
  });
});

window.addEventListener('unhandledrejection', (event) => {
  logError('window.unhandled_rejection', event.reason);
});

void syncPendingOperations().catch((error) => logError('offline_sync.initial_failed', error));

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>
          <ThemeProvider>
            <AuthProvider>
              <App />
            </AuthProvider>
          </ThemeProvider>
        </BrowserRouter>
      </QueryClientProvider>
    </ErrorBoundary>
  </React.StrictMode>
);
