import 'package:flutter/material.dart';

import 'branding_config.dart';

class BrandingScope extends InheritedWidget {
  const BrandingScope({
    required this.config,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.reloadBranding,
    required super.child,
    super.key,
  });

  final BrandingConfig config;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final Future<void> Function() reloadBranding;

  static BrandingConfig of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<BrandingScope>()
            ?.config ??
        BrandingConfig.fallback;
  }

  static BrandingScope controlsOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BrandingScope>();
    if (scope == null) {
      throw StateError('BrandingScope não encontrado na árvore do app.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(BrandingScope oldWidget) {
    return config != oldWidget.config || themeMode != oldWidget.themeMode;
  }
}
