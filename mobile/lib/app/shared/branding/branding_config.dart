import 'package:flutter/material.dart';

@immutable
class BrandingConfig {
  const BrandingConfig({
    required this.appName,
    required this.light,
    required this.dark,
    required this.fallbackPalette,
  });

  static const apiFallbackPalette = BrandingPalette(
    primary: Color(0xFFDFCCB4),
    secondary: Color(0xFFECDAC3),
    accent: Color(0xFFFEDEB8),
    background: Color(0xFFFEF5E2),
    surface: Color(0xFFF6E8D5),
    surfaceSoft: Color(0xFFFEDEB8),
    border: Color(0xFFECDAC3),
    muted: Color(0xFF8F7E69),
    text: Color(0xFF3A3026),
  );

  static const fallback = BrandingConfig(
    appName: 'Task Manager',
    light: apiFallbackPalette,
    dark: apiFallbackPalette,
    fallbackPalette: apiFallbackPalette,
  );

  final String appName;
  final BrandingPalette light;
  final BrandingPalette dark;
  final BrandingPalette fallbackPalette;

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    return BrandingConfig(
      appName: (json['appName'] as String?)?.trim().isNotEmpty == true
          ? (json['appName'] as String).trim()
          : BrandingConfig.fallback.appName,
      light: BrandingPalette.fromJson(
        json['light'] as Map<String, dynamic>?,
        BrandingConfig.fallback.light,
      ),
      dark: BrandingPalette.fromJson(
        json['dark'] as Map<String, dynamic>?,
        BrandingConfig.fallback.dark,
      ),
      fallbackPalette: BrandingPalette.fromJson(
        json['fallback'] as Map<String, dynamic>?,
        BrandingConfig.fallback.fallbackPalette,
      ),
    );
  }
}

@immutable
class BrandingPalette {
  const BrandingPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceSoft,
    required this.border,
    required this.muted,
    required this.text,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceSoft;
  final Color border;
  final Color muted;
  final Color text;

  factory BrandingPalette.fromJson(
    Map<String, dynamic>? json,
    BrandingPalette fallback,
  ) {
    return BrandingPalette(
      primary: _readColor(json?['primary'], fallback.primary),
      secondary: _readColor(json?['secondary'], fallback.secondary),
      accent: _readColor(json?['accent'], fallback.accent),
      background: _readColor(json?['background'], fallback.background),
      surface: _readColor(json?['surface'], fallback.surface),
      surfaceSoft: _readColor(json?['surfaceSoft'], fallback.surfaceSoft),
      border: _readColor(json?['border'], fallback.border),
      muted: _readColor(json?['muted'], fallback.muted),
      text: _readColor(json?['text'], fallback.text),
    );
  }

  static Color _readColor(Object? value, Color fallback) {
    if (value is! String) {
      return fallback;
    }

    final cleanHex = value.trim().replaceFirst('#', '');
    final normalizedHex = switch (cleanHex.length) {
      6 => 'FF$cleanHex',
      8 => cleanHex,
      _ => null,
    };

    if (normalizedHex == null) {
      return fallback;
    }

    final parsed = int.tryParse(normalizedHex, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
