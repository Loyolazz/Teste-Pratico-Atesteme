import { FormEvent, useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { UserPlus } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useTheme } from '../../context/ThemeContext';
import { showErrorAlert } from '../../services/errorAlertService';
import { toErrorMessage } from '../../utils/formatters';

export function RegisterPage() {
  const navigate = useNavigate();
  const { register, token } = useAuth();
  const { appName } = useTheme();
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (token) {
    return <Navigate to="/" replace />;
  }

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setError('');

    if (!name || !email || password.length < 6) {
      const message = 'Preencha nome, e-mail e uma senha com pelo menos 6 caracteres.';
      setError(message);
      showErrorAlert(message, 'Erro no cadastro');
      return;
    }

    setIsSubmitting(true);
    try {
      await register(name, email, password);
      navigate('/');
    } catch (exception) {
      const message = toErrorMessage(exception);
      setError(message);
      showErrorAlert(message, 'Erro no cadastro');
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="auth-page">
      <section className="auth-panel" aria-labelledby="register-title">
        <div>
          <span className="eyebrow">Cadastro</span>
          <h1 id="register-title">{appName}</h1>
        </div>

        <form className="stack" onSubmit={handleSubmit}>
          <label>
            Nome
            <input
              value={name}
              onChange={(event) => setName(event.target.value)}
              autoComplete="name"
              required
            />
          </label>

          <label>
            E-mail
            <input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              autoComplete="email"
              required
            />
          </label>

          <label>
            Senha
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              autoComplete="new-password"
              minLength={6}
              required
            />
          </label>

          {error && <p className="form-error">{error}</p>}

          <button className="primary-action" type="submit" disabled={isSubmitting}>
            <UserPlus size={18} aria-hidden="true" />
            {isSubmitting ? 'Criando...' : 'Criar conta'}
          </button>
        </form>

        <p className="auth-link">
          Já tem conta? <Link to="/login">Entrar</Link>
        </p>
      </section>
    </main>
  );
}
