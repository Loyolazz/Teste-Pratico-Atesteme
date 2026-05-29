import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { queryClient } from '../app/queryClient';
import { authService } from '../services/authService';
import { localDatabase } from '../services/localDatabase';
import { tokenStorage } from '../services/tokenStorage';
import type { User } from '../types/api';
import { logError, logWarning } from '../utils/errors';

type AuthContextValue = {
  user: User | null;
  token: string | null;
  isCheckingSession: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (name: string, email: string, password: string) => Promise<void>;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => tokenStorage.get());
  const [user, setUser] = useState<User | null>(null);
  const [isCheckingSession, setIsCheckingSession] = useState(true);

  const logout = useCallback(() => {
    const refreshToken = tokenStorage.getRefresh();
    if (refreshToken) {
      void authService.logout(refreshToken).catch((error) => {
        logWarning('auth.logout_remote_failed', error);
      });
    }
    tokenStorage.clear();
    queryClient.clear();
    void localDatabase.clearAll().catch((error) => {
      logError('auth.local_cache_clear_failed', error);
    });
    setToken(null);
    setUser(null);
  }, []);

  useEffect(() => {
    if (!token) {
      setIsCheckingSession(false);
      return;
    }

    // O Context mantém apenas sessão; listas e mutations ficam no React Query.
    authService.me()
      .then(setUser)
      .catch((error) => {
        logWarning('auth.session_restore_failed', error);
        logout();
      })
      .finally(() => setIsCheckingSession(false));
  }, [logout, token]);

  const login = useCallback(async (email: string, password: string) => {
    const response = await authService.login(email, password);
    await localDatabase.clearAll();
    tokenStorage.setTokens(response.accessToken, response.refreshToken);
    setToken(response.accessToken);
    setUser(response.user);
  }, []);

  const register = useCallback(async (name: string, email: string, password: string) => {
    const response = await authService.register(name, email, password);
    await localDatabase.clearAll();
    tokenStorage.setTokens(response.accessToken, response.refreshToken);
    setToken(response.accessToken);
    setUser(response.user);
  }, []);

  const value = useMemo<AuthContextValue>(() => ({
    user,
    token,
    isCheckingSession,
    login,
    register,
    logout
  }), [isCheckingSession, login, logout, register, token, user]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth deve ser usado dentro de AuthProvider.');
  }

  return context;
}
