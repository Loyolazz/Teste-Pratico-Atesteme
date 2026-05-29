import type { ApiError } from '../types/api';

type ErrorContext = Record<string, unknown>;

export function createApiError({
  message,
  status,
  error = 'CLIENT_ERROR',
  path,
  requestId,
  fieldErrors = [],
  timestamp = new Date().toISOString()
}: {
  message: string;
  status?: number;
  error?: string;
  path?: string;
  requestId?: string | null;
  fieldErrors?: ApiError['fieldErrors'];
  timestamp?: string;
}): ApiError {
  return {
    message,
    status,
    error,
    path,
    requestId: requestId ?? undefined,
    fieldErrors,
    timestamp
  };
}

export function isApiError(error: unknown): error is ApiError {
  return Boolean(
    error
      && typeof error === 'object'
      && 'message' in error
      && (
        'status' in error
        || 'error' in error
        || 'fieldErrors' in error
        || 'requestId' in error
      )
  );
}

export function isNetworkError(error: unknown) {
  return isApiError(error) && (error.status === 0 || error.error === 'NETWORK_ERROR');
}

export function toErrorMessage(error: unknown) {
  if (isApiError(error)) {
    const fieldMessages = error.fieldErrors
      ?.filter((fieldError) => fieldError.message)
      .map((fieldError) => `${fieldError.field}: ${fieldError.message}`)
      .join(' ');

    return fieldMessages ? `${error.message} ${fieldMessages}` : error.message;
  }

  if (error instanceof Error && error.message) {
    return error.message;
  }

  return 'Não foi possível concluir a ação.';
}

export function logError(scope: string, error: unknown, context: ErrorContext = {}) {
  console.error(`[${scope}]`, {
    ...context,
    error: serializeError(error)
  });
}

export function logWarning(scope: string, error: unknown, context: ErrorContext = {}) {
  console.warn(`[${scope}]`, {
    ...context,
    error: serializeError(error)
  });
}

export function logInfo(scope: string, context: ErrorContext = {}) {
  console.info(`[${scope}]`, context);
}

export function serializeError(error: unknown): ErrorContext | string | null {
  if (isApiError(error)) {
    return {
      code: error.error,
      status: error.status,
      message: error.message,
      path: error.path,
      requestId: error.requestId,
      fieldErrors: error.fieldErrors
    };
  }

  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack
    };
  }

  if (typeof error === 'object' && error !== null) {
    return error as ErrorContext;
  }

  if (typeof error === 'string') {
    return error;
  }

  return null;
}
