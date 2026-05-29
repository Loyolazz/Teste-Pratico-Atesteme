import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'shared/branding/branding_config.dart';
import 'shared/branding/branding_scope.dart';
import 'shared/branding/branding_service.dart';
import 'theme/app_theme.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  final _brandingService = BrandingService();
  var _branding = BrandingConfig.fallback;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  Future<void> _loadBranding() async {
    final branding = await _brandingService.load();
    if (mounted) {
      setState(() => _branding = branding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: _branding.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(_branding.light, Brightness.light),
      darkTheme: buildAppTheme(_branding.dark, Brightness.dark),
      builder: (context, child) => BrandingScope(
        config: _branding,
        child: child ?? const SizedBox.shrink(),
      ),
      themeMode: ThemeMode.system,
      routerConfig: Modular.routerConfig,
    );
  }
}
