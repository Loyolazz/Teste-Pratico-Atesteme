import { Component, type ErrorInfo, type ReactNode } from 'react';
import { logError } from '../utils/errors';

type ErrorBoundaryState = {
  hasError: boolean;
};

export class ErrorBoundary extends Component<{ children: ReactNode }, ErrorBoundaryState> {
  state: ErrorBoundaryState = {
    hasError: false
  };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    logError('react.render_error', error, {
      componentStack: errorInfo.componentStack
    });
  }

  render() {
    if (this.state.hasError) {
      return (
        <main className="auth-page">
          <section className="auth-panel" aria-labelledby="runtime-error-title">
            <div>
              <span className="eyebrow">Erro</span>
              <h1 id="runtime-error-title">Algo saiu do fluxo esperado</h1>
            </div>
            <p className="form-error">
              A falha foi registrada no console. Recarregue a página para tentar novamente.
            </p>
          </section>
        </main>
      );
    }

    return this.props.children;
  }
}
