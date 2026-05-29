import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../storage/token_storage.dart';

class HomeRedirectPage extends StatefulWidget {
  const HomeRedirectPage({super.key});

  @override
  State<HomeRedirectPage> createState() => _HomeRedirectPageState();
}

class _HomeRedirectPageState extends State<HomeRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    final token = await Modular.get<TokenStorage>().getToken();
    final route = token == null ? '/auth/login' : '/projects/';
    Modular.to.navigate(route);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

