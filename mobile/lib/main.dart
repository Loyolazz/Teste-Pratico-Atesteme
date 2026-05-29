import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'app/app_module.dart';
import 'app/app_widget.dart';
import 'app/shared/services/app_logger.dart';

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'flutter.framework_error',
          error: details.exception,
          stackTrace: details.stack,
          context: {'library': details.library},
        );
      };

      runApp(ModularApp(module: AppModule(), child: const AppWidget()));
    },
    (error, stackTrace) {
      AppLogger.error('dart.unhandled_error', error: error, stackTrace: stackTrace);
    },
  );
}
