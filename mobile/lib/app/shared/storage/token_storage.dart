import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/app_logger.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const _tokenKey = 'atesteme_taskmanager_token';
  static const _refreshTokenKey = 'atesteme_taskmanager_refresh_token';
  static const _operationTimeout = Duration(seconds: 2);

  final FlutterSecureStorage _storage;
  Future<void>? _loadFuture;
  String? _token;
  String? _refreshToken;
  var _loaded = false;

  Future<String?> getToken() async {
    AppLogger.info('token_storage.get_token.started');
    await _ensureLoaded();
    AppLogger.info('token_storage.get_token.completed', context: {
      'hasToken': _token != null,
    });
    return _token;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    _loaded = true;
    await _runStorageOperation(
      'token_storage.save_token_failed',
      () => _storage.write(key: _tokenKey, value: token),
    );
  }

  Future<String?> getRefreshToken() async {
    AppLogger.info('token_storage.get_refresh_token.started');
    await _ensureLoaded();
    AppLogger.info('token_storage.get_refresh_token.completed', context: {
      'hasRefreshToken': _refreshToken != null,
    });
    return _refreshToken;
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    AppLogger.info('token_storage.save_tokens.started');
    _token = accessToken;
    _refreshToken = refreshToken;
    _loaded = true;

    await _runStorageOperation(
      'token_storage.save_tokens_failed',
      () async {
        await Future.wait([
          _storage.write(key: _tokenKey, value: accessToken),
          _storage.write(key: _refreshTokenKey, value: refreshToken),
        ]);
      },
    );
    AppLogger.info('token_storage.save_tokens.completed');
  }

  Future<void> clear() async {
    AppLogger.info('token_storage.clear.started');
    _token = null;
    _refreshToken = null;
    _loaded = true;

    await _runStorageOperation(
      'token_storage.clear_failed',
      () async {
        await Future.wait([
          _storage.delete(key: _tokenKey),
          _storage.delete(key: _refreshTokenKey),
        ]);
      },
    );
    AppLogger.info('token_storage.clear.completed');
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }

    _loadFuture ??= _loadFromStorage();
    await _loadFuture;
  }

  Future<void> _loadFromStorage() async {
    AppLogger.info('token_storage.load_from_disk.started');
    await _runStorageOperation('token_storage.load_failed', () async {
      final values = await Future.wait([
        _storage.read(key: _tokenKey),
        _storage.read(key: _refreshTokenKey),
      ]);

      _token = values[0];
      _refreshToken = values[1];
      _loaded = true;
    });
    _loaded = true;
    AppLogger.info('token_storage.load_from_disk.completed', context: {
      'hasToken': _token != null,
      'hasRefreshToken': _refreshToken != null,
    });
  }

  Future<void> _runStorageOperation(
    String logMessage,
    Future<void> Function() operation,
  ) async {
    try {
      await operation().timeout(_operationTimeout);
    } catch (error, stackTrace) {
      AppLogger.warning(
        logMessage,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
