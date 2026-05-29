import 'dart:developer' as developer;

class AppLogger {
  static const _name = 'Atesteme';

  static void info(String message, {Map<String, Object?> context = const {}}) {
    developer.log(_format(message, context), name: _name, level: 800);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    developer.log(
      _format(message, context),
      name: _name,
      level: 900,
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
    developer.log(
      _format(message, context),
      name: _name,
      level: 1000,
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
