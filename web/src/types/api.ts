export type User = {
  id: number;
  name: string;
  email: string;
};

export type AuthResponse = {
  accessToken: string;
  refreshToken: string;
  user: User;
};

export type Project = {
  id: number;
  name: string;
  description?: string | null;
  createdAt: string;
  taskCount: number;
};

export type TaskStatus = 'PENDENTE' | 'EM_ANDAMENTO' | 'CONCLUIDA';

export type TaskPriority = 'BAIXA' | 'MEDIA' | 'ALTA';

export type Task = {
  id: number;
  title: string;
  description?: string | null;
  priority: TaskPriority;
  status: TaskStatus;
  createdAt: string;
  projectId: number;
};

export type ProjectPayload = {
  name: string;
  description?: string;
};

export type TaskPayload = {
  title: string;
  description?: string;
  priority: TaskPriority;
  status: TaskStatus;
};

export type ApiError = {
  message: string;
  status?: number;
  error?: string;
  path?: string;
  requestId?: string;
  timestamp?: string;
  fieldErrors?: Array<{ field: string; message: string }>;
};
