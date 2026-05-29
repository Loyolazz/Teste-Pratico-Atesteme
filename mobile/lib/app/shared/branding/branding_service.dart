import 'package:dio/dio.dart';

import '../services/app_logger.dart';
import 'branding_config.dart';

class BrandingService {
  BrandingService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_URL',
                defaultValue: 'http://10.0.2.2:8080/api',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  final Dio _dio;

  Future<BrandingConfig> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/branding');
      final data = response.data;
      if (data == null) {
        throw StateError('Resposta de branding vazia.');
      }
      return BrandingConfig.fromJson(data);
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
