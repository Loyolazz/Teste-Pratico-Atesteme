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
      ErrorWidget.builder = (details) {
        AppLogger.error(
          'flutter.error_widget',
          error: details.exception,
          stackTrace: details.stack,
        );

        return Material(
          color: const Color(0xFFFFF1F2),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFB42318), size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível exibir esta tela.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF7F1D1D),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tente voltar e abrir novamente. Se continuar, reinicie o aplicativo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      };

      runApp(ModularApp(module: AppModule(), child: const AppWidget()));
    },
    (error, stackTrace) {
      AppLogger.error('dart.unhandled_error',
          error: error, stackTrace: stackTrace);
    },
  );
}
