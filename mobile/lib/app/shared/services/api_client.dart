import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'app_error.dart';
import 'app_logger.dart';

class ApiClient {
  ApiClient(this._tokenStorage)
      : _dio = Dio(BaseOptions(
          baseUrl: const String.fromEnvironment(
            'API_URL',
            defaultValue: 'http://10.0.2.2:8080/api',
          ),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final isRefreshRequest = error.requestOptions.path.endsWith('/auth/refresh');
        final refreshToken = await _tokenStorage.getRefreshToken();

        if (statusCode == 401 && !isRefreshRequest && refreshToken != null) {
          try {
            final refreshed = await _refreshToken(refreshToken);
            final request = error.requestOptions;
            request.headers['Authorization'] = 'Bearer ${refreshed.accessToken}';
            final response = await _dio.fetch<dynamic>(request);
            handler.resolve(response);
            return;
          } catch (refreshError, stackTrace) {
            AppLogger.warning(
              'auth.refresh.failed',
              error: refreshError,
              stackTrace: stackTrace,
              context: {'path': '/auth/refresh'},
            );
            await _tokenStorage.clear();
          }
        }

        handler.next(error);
      },
    ));
  }

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Future<T> get<T>(String path) async {
    return _send('GET', path, () => _dio.get<T>(path));
  }

  Future<T> post<T>(String path, Map<String, dynamic> data) async {
    return _send('POST', path, () => _dio.post<T>(path, data: data));
  }

  Future<void> postVoid(String path, Map<String, dynamic> data) async {
    await _sendVoid('POST', path, () => _dio.post<void>(path, data: data));
  }

  Future<T> put<T>(String path, Map<String, dynamic> data) async {
    return _send('PUT', path, () => _dio.put<T>(path, data: data));
  }

  Future<T> patch<T>(String path, Map<String, dynamic> data) async {
    return _send('PATCH', path, () => _dio.patch<T>(path, data: data));
  }

  Future<T> delete<T>(String path) async {
    return _send('DELETE', path, () => _dio.delete<T>(path));
  }

  Future<void> deleteVoid(String path) async {
    await _sendVoid('DELETE', path, () => _dio.delete<void>(path));
  }

  Future<T> _send<T>(
    String method,
    String path,
    Future<Response<T>> Function() request,
  ) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (error, stackTrace) {
      final appError = AppException.fromDio(error);
      AppLogger.error(
        'api.request.failed',
        error: appError,
        stackTrace: stackTrace,
        context: {
          'method': method,
          'path': path,
          'statusCode': appError.statusCode,
          'code': appError.code,
          'requestId': appError.requestId,
        },
      );
      throw appError;
    } catch (error, stackTrace) {
      AppLogger.error(
        'api.request.unexpected',
        error: error,
        stackTrace: stackTrace,
        context: {'method': method, 'path': path},
      );
      rethrow;
    }
  }

  Future<void> _sendVoid(
    String method,
    String path,
    Future<Response<void>> Function() request,
  ) async {
    try {
      await request();
    } on DioException catch (error, stackTrace) {
      final appError = AppException.fromDio(error);
      AppLogger.error(
        'api.request.failed',
        error: appError,
        stackTrace: stackTrace,
        context: {
          'method': method,
          'path': path,
          'statusCode': appError.statusCode,
          'code': appError.code,
          'requestId': appError.requestId,
        },
      );
      throw appError;
    } catch (error, stackTrace) {
      AppLogger.error(
        'api.request.unexpected',
        error: error,
        stackTrace: stackTrace,
        context: {'method': method, 'path': path},
      );
      rethrow;
    }
  }

  Future<_RefreshResponse> _refreshToken(String refreshToken) async {
    final dio = Dio(BaseOptions(
      baseUrl: _dio.options.baseUrl,
      connectTimeout: _dio.options.connectTimeout,
      receiveTimeout: _dio.options.receiveTimeout,
    ));
    final response = await dio.post<Map<String, dynamic>>('/auth/refresh', data: {
      'refreshToken': refreshToken,
    });
    final data = response.data!;
    final refreshed = _RefreshResponse(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
    await _tokenStorage.saveTokens(refreshed.accessToken, refreshed.refreshToken);
    return refreshed;
  }
}

class _RefreshResponse {
  const _RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}
