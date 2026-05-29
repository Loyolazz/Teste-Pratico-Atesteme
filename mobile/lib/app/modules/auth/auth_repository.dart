import '../../shared/models/auth_models.dart';
import '../../shared/services/api_client.dart';

class AuthRepository {
  const AuthRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResponseModel> login(String email, String password) async {
    final data = await _apiClient.post<Map<String, dynamic>>('/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResponseModel.fromJson(data);
  }

  Future<AuthResponseModel> register(String name, String email, String password) async {
    final data = await _apiClient.post<Map<String, dynamic>>('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return AuthResponseModel.fromJson(data);
  }

  Future<void> logout(String refreshToken) {
    return _apiClient.postVoid('/auth/logout', {'refreshToken': refreshToken});
  }
}
