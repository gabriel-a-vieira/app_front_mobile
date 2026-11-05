import 'package:app_front_mobile/services/auth_service.dart';
import 'package:app_front_mobile/widgets/forgot_password_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/test_app.dart';

class MockAuthService extends Mock implements AuthService {}

/// Covers the "Recuperar senha" modal: e-mail step -> code step, local
/// validation (6-digit code, password length/match) before calling the
/// backend, the backend's error message surfacing, and popping with the
/// e-mail so the login modal can prefill it.
void main() {
  late MockAuthService authService;

  setUp(() {
    authService = MockAuthService();
    when(
      () => authService.requestPasswordReset(email: any(named: 'email')),
    ).thenAnswer((_) async {});
  });

  /// Pumps a page with a button that opens the dialog the same way the
  /// login modal does, and records what the dialog popped with.
  Future<List<String?>> pumpOpener(WidgetTester tester) async {
    await useDesktopTestSurface(tester);
    final popped = <String?>[];

    await tester.pumpWidget(
      testApp(
        Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popped.add(
                  await showDialog<String>(
                    context: context,
                    builder: (_) => Dialog(
                      child: ForgotPasswordDialog(
                        initialEmail: 'ana@email.com',
                        authService: authService,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return popped;
  }

  Future<void> goToCodeStep(WidgetTester tester) async {
    await tester.tap(find.text('Enviar código'));
    await tester.pump();
  }

  testWidgets(
    'sends the code for the prefilled e-mail and shows the code step',
    (tester) async {
      await pumpOpener(tester);

      await goToCodeStep(tester);

      verify(
        () => authService.requestPasswordReset(email: 'ana@email.com'),
      ).called(1);
      expect(find.textContaining('ana@email.com'), findsOneWidget);
      expect(find.byKey(const Key('forgotPasswordCode')), findsOneWidget);
      // Resend is on cooldown right after sending.
      expect(find.textContaining('Reenviar código em'), findsOneWidget);

      // Let the 60s cooldown timer finish so the test doesn't leave it pending.
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Reenviar código'), findsOneWidget);
    },
  );

  testWidgets('validates code and passwords locally before calling backend', (
    tester,
  ) async {
    await pumpOpener(tester);
    await goToCodeStep(tester);

    await tester.enterText(find.byKey(const Key('forgotPasswordCode')), '12');
    await tester.enterText(
      find.byKey(const Key('forgotPasswordNewPassword')),
      '123',
    );
    await tester.enterText(
      find.byKey(const Key('forgotPasswordConfirmPassword')),
      '999',
    );
    await tester.tap(find.text('Redefinir senha'));
    await tester.pump();

    expect(find.text('O código deve ter 6 dígitos'), findsOneWidget);
    expect(
      find.text('A senha deve ter pelo menos 6 caracteres'),
      findsOneWidget,
    );
    expect(find.text('As senhas não conferem'), findsOneWidget);
    verifyNever(
      () => authService.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    );

    await tester.pump(const Duration(seconds: 61));
  });

  testWidgets('on success pops with the e-mail', (tester) async {
    when(
      () => authService.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});

    final popped = await pumpOpener(tester);
    await goToCodeStep(tester);

    await tester.enterText(
      find.byKey(const Key('forgotPasswordCode')),
      '123456',
    );
    await tester.enterText(
      find.byKey(const Key('forgotPasswordNewPassword')),
      'senha-nova',
    );
    await tester.enterText(
      find.byKey(const Key('forgotPasswordConfirmPassword')),
      'senha-nova',
    );
    await tester.tap(find.text('Redefinir senha'));
    await tester.pumpAndSettle();

    verify(
      () => authService.confirmPasswordReset(
        email: 'ana@email.com',
        code: '123456',
        newPassword: 'senha-nova',
      ),
    ).called(1);
    expect(popped, ['ana@email.com']);
    expect(find.byType(ForgotPasswordDialog), findsNothing);
  });

  testWidgets('shows the backend message and stays open on invalid code', (
    tester,
  ) async {
    final requestOptions = RequestOptions(path: '/auth/password-reset/confirm');
    when(
      () => authService.confirmPasswordReset(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 400,
          data: {
            'message': 'Código inválido ou expirado. Solicite um novo código.',
          },
        ),
      ),
    );

    final popped = await pumpOpener(tester);
    await goToCodeStep(tester);

    await tester.enterText(
      find.byKey(const Key('forgotPasswordCode')),
      '000000',
    );
    await tester.enterText(
      find.byKey(const Key('forgotPasswordNewPassword')),
      'senha-nova',
    );
    await tester.enterText(
      find.byKey(const Key('forgotPasswordConfirmPassword')),
      'senha-nova',
    );
    await tester.tap(find.text('Redefinir senha'));
    await tester.pump();

    expect(
      find.text('Código inválido ou expirado. Solicite um novo código.'),
      findsOneWidget,
    );
    expect(find.byType(ForgotPasswordDialog), findsOneWidget);
    expect(popped, isEmpty);

    await tester.pump(const Duration(seconds: 61));
  });
}
