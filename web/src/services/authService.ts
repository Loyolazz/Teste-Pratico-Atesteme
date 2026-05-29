import { apiRequest } from './apiClient';
import type { AuthResponse, User } from '../types/api';

export const authService = {
  login(email: string, password: string) {
    return apiRequest<AuthResponse>('/auth/login', {
      method: 'POST',
      body: { email, password }
    });
  },
  register(name: string, email: string, password: string) {
    return apiRequest<AuthResponse>('/auth/register', {
      method: 'POST',
      body: { name, email, password }
    });
  },
  refresh(refreshToken: string) {
    return apiRequest<AuthResponse>('/auth/refresh', {
      method: 'POST',
      body: { refreshToken },
      skipAuthRefresh: true
    });
  },
  logout(refreshToken: string) {
    return apiRequest<void>('/auth/logout', {
      method: 'POST',
      body: { refreshToken },
      skipAuthRefresh: true
    });
  },
  me() {
    return apiRequest<User>('/auth/me');
  }
};
