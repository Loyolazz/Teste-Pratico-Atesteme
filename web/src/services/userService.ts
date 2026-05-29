import { apiRequest } from './apiClient';
import type { AssignableUser } from '../types/api';
import { logWarning } from '../utils/errors';

export const userService = {
  async listAssignable() {
    try {
      return await apiRequest<AssignableUser[]>('/users');
    } catch (error) {
      logWarning('users.list_assignable.failed', error);
      return [];
    }
  }
};
