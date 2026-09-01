import 'package:app_front_mobile/pages/login_page.dart';
import 'package:app_front_mobile/pages/register_page.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';

class AuthGate {
  AuthGate._();

  static final TokenStorage _tokenStorage = TokenStorage();

  static Future<bool> isAuthenticated() async {
    return await _tokenStorage.isAccessTokenValid();
  }

  static Future<bool> requireLogin(
    BuildContext context, {
    required String reason,
  }) async {
    if (await isAuthenticated()) {
      return true;
    }

    if (!context.mounted) {
      return false;
    }

    final action = await showDialog<_AuthAction>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Entre para continuar'),
          content: Text(reason),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_AuthAction.register),
              child: const Text('Criar conta'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_AuthAction.login),
              child: const Text('Entrar'),
            ),
          ],
        );
      },
    );

    if (!context.mounted) {
      return false;
    }

    if (action == _AuthAction.login) {
      return _showLogin(context);
    }

    if (action == _AuthAction.register) {
      return _showRegister(context);
    }

    return false;
  }

  static Future<bool> _showLogin(BuildContext context) async {
    bool success = false;
    bool openRegister = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LoginPage(
            onLoginSuccess: (_) {
              success = true;

              Navigator.of(dialogContext).pop();
            },
            onRegisterTap: () {
              openRegister = true;

              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );

    if (success) {
      return true;
    }

    if (openRegister && context.mounted) {
      return _showRegister(context);
    }

    return false;
  }

  static Future<bool> _showRegister(BuildContext context) async {
    bool goToLogin = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: RegisterPage(
            onLoginTap: () {
              goToLogin = true;

              Navigator.of(dialogContext).pop();
            },
            onRegisterSuccess: () {
              goToLogin = true;

              Navigator.of(dialogContext).pop();
            },
          ),
        );
      },
    );

    if (goToLogin && context.mounted) {
      return _showLogin(context);
    }

    return false;
  }
}

enum _AuthAction { login, register }
