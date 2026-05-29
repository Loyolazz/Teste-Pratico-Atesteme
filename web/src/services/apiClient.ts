import { tokenStorage } from './tokenStorage';
import { createApiError, logError, logWarning } from '../utils/errors';

const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8080/api';

type RequestOptions = Omit<RequestInit, 'body'> & {
  body?: BodyInit | Record<string, unknown> | null;
  skipAuthRefresh?: boolean;
};

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  return executeRequest<T>(path, options, true);
}

async function executeRequest<T>(
  path: string,
  options: RequestOptions,
  canRefresh: boolean
): Promise<T> {
  const method = options.method ?? 'GET';
  const token = tokenStorage.get();
  const headers = new Headers(options.headers);

  if (!(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  let response: Response;

  try {
    response = await fetch(`${API_URL}${path}`, {
      ...options,
      headers,
      body: options.body && !(options.body instanceof FormData)
        ? JSON.stringify(options.body)
        : options.body
    });
  } catch (error) {
    const apiError = createApiError({
      message: navigator.onLine
        ? 'Não foi possível conectar ao servidor.'
        : 'Sem conexão com a internet.',
      status: 0,
      error: 'NETWORK_ERROR',
      path
    });
    logError('api.request.network_error', apiError, { method, path, cause: error });
    throw apiError;
  }

  if (response.status === 204) {
    return undefined as T;
  }

  const requestId = response.headers.get('X-Request-Id');
  const data = await response.json().catch((error) => {
    logWarning('api.response.invalid_json', error, {
      method,
      path,
      status: response.status,
      requestId
    });
    return null;
  });

  if (response.status === 401 && canRefresh && !options.skipAuthRefresh) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      return executeRequest<T>(path, options, false);
    }
  }

  if (!response.ok) {
    const error = createApiError({
      message: data?.message ?? 'Não foi possível concluir a solicitação.',
      status: response.status,
      error: data?.error ?? `HTTP_${response.status}`,
      path: data?.path ?? path,
      requestId: data?.requestId ?? requestId,
      timestamp: data?.timestamp,
      fieldErrors: data?.fieldErrors ?? []
    });
    logError('api.request.failed', error, {
      method,
      path,
      status: response.status,
      statusText: response.statusText
    });
    throw error;
  }

  return data as T;
}

async function refreshAccessToken() {
  const refreshToken = tokenStorage.getRefresh();
  if (!refreshToken) {
    return false;
  }

  let response: Response;

  try {
    response = await fetch(`${API_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken })
    });
  } catch (error) {
    logWarning('auth.refresh.network_error', error, { path: '/auth/refresh' });
    return false;
  }

  if (!response.ok) {
    logWarning('auth.refresh.failed', createApiError({
      message: 'Refresh token recusado pelo servidor.',
      status: response.status,
      error: `HTTP_${response.status}`,
      path: '/auth/refresh',
      requestId: response.headers.get('X-Request-Id')
    }));
    tokenStorage.clear();
    return false;
  }

  const data = await response.json().catch((error) => {
    logWarning('auth.refresh.invalid_json', error, { path: '/auth/refresh' });
    return null;
  });
  if (!data?.accessToken || !data?.refreshToken) {
    logWarning('auth.refresh.invalid_payload', createApiError({
      message: 'Resposta inválida ao renovar sessão.',
      status: response.status,
      error: 'INVALID_REFRESH_RESPONSE',
      path: '/auth/refresh',
      requestId: response.headers.get('X-Request-Id')
    }));
    tokenStorage.clear();
    return false;
  }

  tokenStorage.setTokens(data.accessToken, data.refreshToken);
  return true;
}
