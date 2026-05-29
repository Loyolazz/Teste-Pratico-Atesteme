import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

class AppLogger {
  static const _name = 'TaskManager';

  static void info(String message, {Map<String, Object?> context = const {}}) {
    _write(message, level: 800, context: context);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      message,
      level: 900,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    _write(
      message,
      level: 1000,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _write(
    String message, {
    required int level,
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final formatted = _format(message, context);
    debugPrint('console.log [$_name] $formatted');
    if (error != null) {
      debugPrint('console.log [$_name] error=$error');
    }

    developer.log(
      formatted,
      name: _name,
      level: level,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static String _format(String message, Map<String, Object?> context) {
    if (context.isEmpty) {
      return message;
    }

    return '$message | context=$context';
  }
}
