import { Navigate, Outlet } from 'react-router-dom';
import { LoadingScreen } from '../components/LoadingScreen';
import { useAuth } from '../context/AuthContext';

export function ProtectedRoute() {
  const { token, isCheckingSession } = useAuth();

  if (isCheckingSession) {
    return <LoadingScreen />;
  }

  return token ? <Outlet /> : <Navigate to="/login" replace />;
}

