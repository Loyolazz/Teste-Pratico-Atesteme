import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../services/app_logger.dart';
import '../storage/token_storage.dart';

class HomeRedirectPage extends StatefulWidget {
  const HomeRedirectPage({super.key});

  @override
  State<HomeRedirectPage> createState() => _HomeRedirectPageState();
}

class _HomeRedirectPageState extends State<HomeRedirectPage> {
  var _message = 'Verificando sessão salva...';

  @override
  void initState() {
    super.initState();
    AppLogger.info('screen.home_redirect.opened');
    _redirect();
  }

  Future<void> _redirect() async {
    AppLogger.info('screen.home_redirect.reading_token');
    final token = await Modular.get<TokenStorage>().getToken();
    final route = token == null ? '/auth/login' : '/projects/';
    AppLogger.info('screen.home_redirect.route_decided', context: {
      'hasToken': token != null,
      'route': route,
    });
    if (mounted) {
      setState(() =>
          _message = 'Abrindo ${token == null ? 'login' : 'projetos'}...');
    }
    Modular.to.navigate(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
