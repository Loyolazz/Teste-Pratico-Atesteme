import 'package:flutter/material.dart';

void showErrorSnackBar(BuildContext context, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted || message.trim().isEmpty) {
      return;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: colorScheme.onError,
          onPressed: () => messenger.hideCurrentSnackBar(),
        ),
      ),
    );
  });
}
