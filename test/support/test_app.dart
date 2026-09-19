import 'package:app_front_mobile/l10n/app_localizations.dart';
import 'package:app_front_mobile/locale_provider.dart';
import 'package:app_front_mobile/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Wraps [home] the same way `main.dart` does: the localization delegates
/// and the `ThemeNotifier`/`LocaleProvider` providers every screen expects
/// from its ancestors. Every full-page widget test needs this now that
/// `AppScaffold` (used by every page) renders `AppHeader`, which reads
/// `AppLocalizations.of(context)` and `Provider.of<LocaleProvider>` -- a bare
/// `MaterialApp(home: ...)` without them fails with a null-check error
/// instead of the page's own test failure.
///
/// Locale is pinned to pt_BR so assertions on visible text don't depend on
/// the test environment's platform locale.
Widget testApp(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: home,
    ),
  );
}

/// AppHeader lays out the logo + nav + theme/language/login controls for
/// this app's actual desktop/web target (every page body caps at maxWidth
/// 1180-1200), not the framework's default 800x600 test surface, which is
/// too narrow for the title Row and overflows. Call this before pumping any
/// full page wrapped in [testApp].
Future<void> useDesktopTestSurface(WidgetTester tester) async {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;

  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}
