import 'package:flutter/foundation.dart';

const _configuredApiUrl = String.fromEnvironment('API_URL');

String resolveApiBaseUrl() {
  if (_configuredApiUrl.isNotEmpty) {
    return _configuredApiUrl;
  }

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080/api';
  }

  return 'http://localhost:8080/api';
}
