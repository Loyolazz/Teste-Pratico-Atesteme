import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const _tokenKey = 'atesteme_taskmanager_token';
  static const _refreshTokenKey = 'atesteme_taskmanager_refresh_token';
  final FlutterSecureStorage _storage;

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: _tokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
