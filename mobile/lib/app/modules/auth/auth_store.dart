import 'package:mobx/mobx.dart';

import '../../shared/models/auth_models.dart';
import '../../shared/services/app_error.dart';
import '../../shared/services/app_logger.dart';
import '../../shared/storage/local_database.dart';
import '../../shared/storage/token_storage.dart';
import 'auth_repository.dart';

class AuthStore {
  AuthStore(this._repository, this._tokenStorage, this._localDatabase);

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final LocalDatabase _localDatabase;

  final user = Observable<UserModel?>(null);
  final isLoading = Observable(false);
  final error = Observable<String?>(null);

  late final login = Action(_login);
  late final register = Action(_register);
  late final logout = Action(_logout);

  Future<bool> _login(String email, String password) async {
    return _authenticate(() => _repository.login(email, password));
  }

  Future<bool> _register(String name, String email, String password) async {
    return _authenticate(() => _repository.register(name, email, password));
  }

  Future<bool> _authenticate(Future<AuthResponseModel> Function() request) async {
    isLoading.value = true;
    error.value = null;

    try {
      final response = await request();
      // O token é persistido para manter a sessão ativa entre aberturas do app.
      await _localDatabase.clearAll();
      await _tokenStorage.saveTokens(response.accessToken, response.refreshToken);
      user.value = response.user;
      return true;
    } catch (exception, stackTrace) {
      AppLogger.error('auth.authenticate.failed', error: exception, stackTrace: stackTrace);
      error.value = errorMessageFor(
        exception,
        fallback: 'Não foi possível autenticar. Verifique os dados informados.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _repository.logout(refreshToken);
      } catch (exception, stackTrace) {
        AppLogger.warning('auth.logout_remote_failed', error: exception, stackTrace: stackTrace);
      }
    }
    await _tokenStorage.clear();
    await _localDatabase.clearAll();
    user.value = null;
  }
}
