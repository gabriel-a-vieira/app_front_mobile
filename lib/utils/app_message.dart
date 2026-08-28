import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:flutter/material.dart';

class AppMessage {
  AppMessage._();

  static void success(
    BuildContext context,
    String message,
  ) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: const Color(0xFF1E8F59),
    );
  }

  static void error(
    BuildContext context,
    String message,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    _show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: colorScheme.error,
    );
  }

  static void apiError(
    BuildContext context,
    Object error, {
    String fallback = 'Ocorreu um erro. Tente novamente.',
  }) {
    final message = ApiErrorHandler.getMessage(
      error,
      fallback: fallback,
    );

    AppMessage.error(
      context,
      message,
    );
  }

  static void info(
    BuildContext context,
    String message,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    _show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: colorScheme.primary,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}