import 'package:dio/dio.dart';

class AppException implements Exception {
  const AppException({
    required this.message,
    required this.code,
    this.statusCode,
    this.path,
    this.requestId,
    this.fieldErrors = const [],
  });

  factory AppException.fromDio(DioException error) {
    final response = error.response;
    final data = _asMap(response?.data);
    final statusCode = response?.statusCode;
    final fieldErrors = _fieldErrorsFrom(data?['fieldErrors']);

    return AppException(
      message: data?['message']?.toString() ?? _messageForDio(error),
      code: data?['error']?.toString() ?? (statusCode == null ? 'NETWORK_ERROR' : 'HTTP_$statusCode'),
      statusCode: statusCode,
      path: data?['path']?.toString() ?? error.requestOptions.path,
      requestId: data?['requestId']?.toString() ?? response?.headers.value('x-request-id'),
      fieldErrors: fieldErrors,
    );
  }

  final String message;
  final String code;
  final int? statusCode;
  final String? path;
  final String? requestId;
  final List<AppFieldError> fieldErrors;

  bool get isNetworkError => statusCode == null || code == 'NETWORK_ERROR';

  @override
  String toString() {
    final status = statusCode == null ? '' : ' status=$statusCode';
    final id = requestId == null ? '' : ' requestId=$requestId';
    return 'AppException(code=$code$status$id, message=$message)';
  }
}

class AppFieldError {
  const AppFieldError({
    required this.field,
    required this.message,
  });

  final String field;
  final String message;

  @override
  String toString() => '$field: $message';
}

String errorMessageFor(Object error, {required String fallback}) {
  if (error is AppException) {
    if (error.fieldErrors.isEmpty) {
      return error.message;
    }

    return '${error.message} ${error.fieldErrors.join(' ')}';
  }

  return fallback;
}

bool isOfflineError(Object error) {
  return error is AppException && error.isNetworkError;
}

Map<String, dynamic>? _asMap(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }

  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }

  return null;
}

List<AppFieldError> _fieldErrorsFrom(Object? data) {
  if (data is! List) {
    return const [];
  }

  return data
      .whereType<Map>()
      .map((item) => AppFieldError(
            field: item['field']?.toString() ?? 'campo',
            message: item['message']?.toString() ?? 'valor inválido',
          ))
      .toList();
}

String _messageForDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return 'Não foi possível conectar ao servidor.';
    case DioExceptionType.badResponse:
      return 'Não foi possível concluir a solicitação.';
    case DioExceptionType.cancel:
      return 'Solicitação cancelada.';
    case DioExceptionType.badCertificate:
      return 'Certificado inválido na conexão com o servidor.';
    case DioExceptionType.unknown:
      return 'Erro inesperado de comunicação.';
  }
}
