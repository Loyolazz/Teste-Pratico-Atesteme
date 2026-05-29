import '../../shared/models/auth_models.dart';
import '../../shared/services/api_client.dart';
import '../../shared/services/app_logger.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> login(String email, String password) async {
    AppLogger.info('auth.repository.login.started', context: {
      'email': email,
    });
    final data = await _apiClient.post<Map<String, dynamic>>('/auth/login', {
      'email': email,
      'password': password,
    });
    AppLogger.info('auth.repository.login.response_parsing');
    final response = AuthResponseModel.fromJson(data);
    AppLogger.info('auth.repository.login.completed', context: {
      'userId': response.user.id,
    });
    return response;
  }

  Future<AuthResponseModel> register(
      String name, String email, String password) async {
    AppLogger.info('auth.repository.register.started', context: {
      'email': email,
    });
    final data = await _apiClient.post<Map<String, dynamic>>('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    AppLogger.info('auth.repository.register.response_parsing');
    final response = AuthResponseModel.fromJson(data);
    AppLogger.info('auth.repository.register.completed', context: {
      'userId': response.user.id,
    });
    return response;
  }

  Future<void> logout(String refreshToken) {
    AppLogger.info('auth.repository.logout.started');
    return _apiClient.postVoid('/auth/logout', {'refreshToken': refreshToken});
  }
}
