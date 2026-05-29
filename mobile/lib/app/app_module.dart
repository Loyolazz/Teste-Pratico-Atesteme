import 'package:flutter_modular/flutter_modular.dart';

import 'modules/auth/auth_module.dart';
import 'modules/auth/auth_repository.dart';
import 'modules/auth/auth_store.dart';
import 'modules/projects/project_module.dart';
import 'modules/projects/project_repository.dart';
import 'modules/projects/project_store.dart';
import 'modules/tasks/task_module.dart';
import 'modules/tasks/task_repository.dart';
import 'modules/tasks/task_store.dart';
import 'modules/users/user_repository.dart';
import 'shared/services/api_client.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/offline_sync_service.dart';
import 'shared/storage/local_database.dart';
import 'shared/storage/token_storage.dart';
import 'shared/widgets/appearance_page.dart';
import 'shared/widgets/home_redirect_page.dart';
import 'shared/widgets/offline_queue_page.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    i.addLazySingleton(TokenStorage.new);
    i.addLazySingleton(LocalDatabase.new);
    i.addLazySingleton(() => ApiClient(i<TokenStorage>()));
    i.addLazySingleton(NotificationService.new);
    i.addLazySingleton(
        () => OfflineSyncService(i<ApiClient>(), i<LocalDatabase>()));
    i.addLazySingleton(() => AuthRepository(i<ApiClient>()));
    i.addLazySingleton(() =>
        AuthStore(i<AuthRepository>(), i<TokenStorage>(), i<LocalDatabase>()));
    i.addLazySingleton(() => UserRepository(i<ApiClient>()));
    i.addLazySingleton(() => ProjectRepository(
        i<ApiClient>(), i<LocalDatabase>(), i<OfflineSyncService>()));
    i.addLazySingleton(() => ProjectStore(i<ProjectRepository>()));
    i.addLazySingleton(() => TaskRepository(
        i<ApiClient>(), i<LocalDatabase>(), i<OfflineSyncService>()));
    i.addLazySingleton(
        () => TaskStore(i<TaskRepository>(), i<NotificationService>()));
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (_) => const HomeRedirectPage());
    r.child('/appearance/', child: (_) => const AppearancePage());
    r.module('/auth', module: AuthModule());
    r.child('/offline/', child: (_) => const OfflineQueuePage());
    r.module('/projects', module: ProjectModule());
    r.module('/tasks', module: TaskModule());
  }
}
