import '../../shared/services/api_client.dart';
import '../../shared/services/app_logger.dart';
import 'user_model.dart';

class UserRepository {
  const UserRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<UserModel>> listAssignable() async {
    try {
      AppLogger.info('users.repository.list_assignable.started');
      final data = await _apiClient.get<List<dynamic>>('/users');
      final users =
          data.cast<Map<String, dynamic>>().map(UserModel.fromJson).toList();
      AppLogger.info('users.repository.list_assignable.completed',
          context: {'items': users.length});
      return users;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'users.list_assignable.failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const [];
    }
  }
}
