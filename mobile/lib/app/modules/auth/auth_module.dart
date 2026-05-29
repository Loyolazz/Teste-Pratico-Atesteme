import 'package:flutter_modular/flutter_modular.dart';

import 'login_page.dart';
import 'register_page.dart';

class AuthModule extends Module {
  @override
  void routes(RouteManager r) {
    r.child('/login', child: (_) => const LoginPage());
    r.child('/register', child: (_) => const RegisterPage());
  }
}

