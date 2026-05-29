import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'shared/branding/branding_config.dart';
import 'shared/branding/branding_scope.dart';
import 'shared/branding/branding_service.dart';
import 'shared/services/app_logger.dart';
import 'theme/app_theme.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  static const _themeModeKey = 'theme_mode';

  final _brandingService = BrandingService();
  final _storage = const FlutterSecureStorage();
  var _branding = BrandingConfig.fallback;
  var _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    AppLogger.info('app_widget.init');
    _loadThemeMode();
    _loadBranding();
  }

  Future<void> _loadThemeMode() async {
    AppLogger.info('app_widget.theme_mode_load_started');
    try {
      final savedThemeMode = await _storage.read(key: _themeModeKey);
      final nextThemeMode = _themeModeFromStorage(savedThemeMode);
      AppLogger.info('app_widget.theme_mode_load_finished', context: {
        'themeMode': nextThemeMode.name,
      });
      if (mounted) {
        setState(() => _themeMode = nextThemeMode);
      }
    } catch (error, stackTrace) {
      AppLogger.warning(
        'app_widget.theme_mode_load_failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _loadBranding() async {
    AppLogger.info('app_widget.branding_load_started');
    final branding = await _brandingService.load();
    AppLogger.info('app_widget.branding_load_finished', context: {
      'appName': branding.appName,
    });
    if (mounted) {
      setState(() => _branding = branding);
    }
  }

  Future<void> _setThemeMode(ThemeMode themeMode) async {
    AppLogger.info('app_widget.theme_mode_changed',
        context: {'themeMode': themeMode.name});
    setState(() => _themeMode = themeMode);
    try {
      await _storage.write(key: _themeModeKey, value: themeMode.name);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'app_widget.theme_mode_save_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'themeMode': themeMode.name},
      );
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
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
        reloadBranding: _loadBranding,
        child: child ?? const SizedBox.shrink(),
      ),
      themeMode: _themeMode,
      routerConfig: Modular.routerConfig,
    );
  }
}

ThemeMode _themeModeFromStorage(String? value) {
  return switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
