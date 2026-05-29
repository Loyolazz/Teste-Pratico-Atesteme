import 'dart:async';

import 'package:mobx/mobx.dart';

import '../../shared/models/auth_models.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/storage/local_database.dart';
import '../../shared/storage/token_storage.dart';
import 'auth_repository.dart';

class AuthStore {
  AuthStore(this._repository, this._tokenStorage, this._localDatabase);

  static const _authTimeout = Duration(seconds: 15);
  static const _backgroundTaskTimeout = Duration(seconds: 3);

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final LocalDatabase _localDatabase;

  final user = Observable<UserModel?>(null);
  final isLoading = Observable(false);
  final error = Observable<String?>(null);
  final loadingPhase = Observable<String?>(null);

  Future<bool> login(String email, String password) {
    return _authenticate(
      operation: 'login',
      loadingLabel: 'Entrando...',
      request: () => _repository.login(email, password),
    );
  }

  Future<bool> register(String name, String email, String password) {
    return _authenticate(
      operation: 'register',
      loadingLabel: 'Criando conta...',
      request: () => _repository.register(name, email, password),
    );
  }

  Future<void> logout() {
    return _logout();
  }

  Future<bool> _authenticate({
    required String operation,
    required String loadingLabel,
    required Future<AuthResponseModel> Function() request,
  }) async {
    runInAction(() {
      isLoading.value = true;
      error.value = null;
    });
    _setPhase('$loadingLabel Preparando chamada...');

    try {
      AppLogger.info('auth.authenticate.started', context: {
        'operation': operation,
      });
      _setPhase('$loadingLabel Enviando para a API...');
      final response = await request().timeout(_authTimeout);
      AppLogger.info('auth.authenticate.response_received', context: {
        'operation': operation,
        'userId': response.user.id,
        'email': response.user.email,
      });
      _setPhase('$loadingLabel Resposta recebida. Abrindo app...');
      _persistSession(response);
      runInAction(() => user.value = response.user);
      AppLogger.info('auth.authenticate.completed', context: {
        'operation': operation,
      });
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error(
        'auth.authenticate.failed',
        error: exception,
        stackTrace: stackTrace,
        context: {'operation': operation},
      );
      runInAction(() {
        error.value = errorMessageFor(
          exception,
          fallback:
              'Não foi possível autenticar. Verifique os dados informados.',
        );
      });
      return false;
    } finally {
      runInAction(() {
        isLoading.value = false;
        loadingPhase.value = null;
      });
      AppLogger.info('auth.authenticate.loading_finished', context: {
        'operation': operation,
      });
    }
  }

  void _persistSession(AuthResponseModel response) {
    AppLogger.info('auth.persist_session.started', context: {
      'userId': response.user.id,
    });
    unawaited(_tokenStorage
        .saveTokens(response.accessToken, response.refreshToken)
        .timeout(_backgroundTaskTimeout)
        .then((_) {
      AppLogger.info('auth.token_save_completed');
    }).catchError((Object exception, StackTrace stackTrace) {
      AppLogger.warning(
        'auth.token_save_failed',
        error: exception,
        stackTrace: stackTrace,
      );
    }));

    unawaited(
        _localDatabase.clearAll().timeout(_backgroundTaskTimeout).then((_) {
      AppLogger.info('auth.local_cache_clear_completed');
    }).catchError((Object exception, StackTrace stackTrace) {
      AppLogger.warning(
        'auth.local_cache_clear_failed',
        error: exception,
        stackTrace: stackTrace,
      );
    }));
  }

  Future<void> _logout() async {
    AppLogger.info('auth.logout.started');
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken);
      } catch (exception, stackTrace) {
        AppLogger.warning('auth.logout_remote_failed',
            error: exception, stackTrace: stackTrace);
      }
    }
    await _tokenStorage.clear();
    await _localDatabase.clearAll();
    runInAction(() => user.value = null);
    AppLogger.info('auth.logout.completed');
  }

  void _setPhase(String message) {
    runInAction(() => loadingPhase.value = message);
    AppLogger.info('auth.loading_phase', context: {'phase': message});
  }
}
