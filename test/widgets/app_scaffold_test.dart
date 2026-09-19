import 'package:app_front_mobile/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Regression coverage for the shared header/footer: every screen builds on
/// AppScaffold instead of a bare Scaffold+AppBar, so it must always render
/// the same top nav / admin gating / theme-language-login controls and the
/// same footer brand, instead of drifting per page again (the exact problem
/// this component was introduced to fix).
void main() {
  // AppHeader/AuthSession read the stored token via TokenStorage
  // (flutter_secure_storage) on init; with no plugin registered in the
  // widget-test environment the channel call never completes on its own, so
  // stub it to resolve to "no token" quickly instead of hanging.
  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  testWidgets(
    'renders the shared header nav/logo and the footer brand for a logged-out visitor',
    (tester) async {
      await useDesktopTestSurface(tester);

      await tester.pumpWidget(
        testApp(const AppScaffold(body: Text('conteudo da tela'))),
      );

      // AuthSession.refreshProfile() fires a real (unmocked) HTTP call in
      // the background and fails offline -- let it settle before asserting,
      // same reasoning as the ClientFormPage regression test.
      await tester.pump(const Duration(milliseconds: 200));

      // The page's own body still renders untouched.
      expect(find.text('conteudo da tela'), findsOneWidget);

      // Header logo + footer brand mark both say "softix".
      expect(find.text('softix'), findsNWidgets(2));
      // Header: nav items, no admin menu for a logged-out visitor.
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('ADMIN'), findsNothing);

      // Footer: brand mark + copyright line, distinct from the header logo.
      expect(
        find.textContaining('Softix — Sistema de agendamentos'),
        findsOneWidget,
      );
    },
  );

  testWidgets('AppScaffold body keeps working even while the footer is present', (
    tester,
  ) async {
    await useDesktopTestSurface(tester);

    await tester.pumpWidget(
      testApp(
        AppScaffold(
          body: ElevatedButton(
            onPressed: () {},
            child: const Text('Acao da tela'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.widgetWithText(ElevatedButton, 'Acao da tela'), findsOneWidget);
  });
}
