import 'package:dio/dio.dart';

import '../services/api_config.dart';
import '../services/app_logger.dart';
import 'branding_config.dart';

class BrandingService {
  BrandingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: resolveApiBaseUrl(),
              connectTimeout: const Duration(seconds: 10),
              sendTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  Future<BrandingConfig> load() async {
    try {
      AppLogger.info('branding.load_started', context: {
        'url': '${_dio.options.baseUrl}/branding',
      });
      final response = await _dio.get<Map<String, dynamic>>('/branding');
      AppLogger.info('branding.load_response', context: {
        'statusCode': response.statusCode,
      });
      final data = response.data;
      if (data == null) {
        throw StateError('Resposta de branding vazia.');
      }
      final branding = BrandingConfig.fromJson(data);
      AppLogger.info('branding.load_completed', context: {
        'appName': branding.appName,
      });
      return branding;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'branding.load_failed_using_fallback',
        error: error,
        stackTrace: stackTrace,
        context: {'path': '/branding'},
      );
      return BrandingConfig.fallback;
    }
  }
}
