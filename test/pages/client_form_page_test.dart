import 'package:app_front_mobile/pages/client_form_page.dart';
import 'package:app_front_mobile/services/city_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Regression coverage for the UF/Cidade fields: ClientFormPage used to be
/// the only cadastro form using a plain DropdownButtonFormField for UF and
/// Cidade, while every other form (e.g. ProfessionalFormPage) opens the
/// shared StateLookupModal/CityLookupModal search dialog instead. This
/// pins the fix -- read-only, search-triggering fields, not dropdowns --
/// so the two don't drift apart again.
void main() {
  // ClientFormPage isn't built for dependency injection (its TokenStorage
  // and *Service instances are constructed internally, not passed in), so
  // initState's _loadInitialData() always makes a real TokenStorage call.
  // With no plugin registered in the widget-test environment, an unmocked
  // flutter_secure_storage MethodChannel call never completes (it's queued
  // in the channel buffers, not rejected) and the page hangs on its loading
  // spinner forever. Stub the channel to return null quickly instead --
  // _getToken() then throws "Token nao encontrado", which _loadInitialData
  // already catches, and the form renders with _states/_paymentMethods
  // empty, which is enough to assert on the UF/Cidade field widgets.
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
    'UF and Cidade are search fields that open the shared lookup modal, not dropdowns',
    (tester) async {
      await useDesktopTestSurface(tester);

      await tester.pumpWidget(
        testApp(const ClientFormPage(currentUserRole: 'COMPANY_ADMIN')),
      );

      // _loadInitialData() also calls StateService/ClientService for real
      // (unmocked) over HTTP; let that resolve or fail before asserting so
      // the loading spinner has been replaced by the actual form.
      // pumpAndSettle can't be used here: the loading state renders an
      // indeterminate CircularProgressIndicator, whose animation never
      // "settles" on its own, so it would just run until pumpAndSettle's
      // own timeout.
      for (var i = 0; i < 50 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byTooltip('Selecionar UF'), findsOneWidget);
      expect(find.byTooltip('Selecionar cidade'), findsOneWidget);

      expect(find.byType(DropdownButtonFormField<StateOption>), findsNothing);
      expect(find.byType(DropdownButtonFormField<CityOption>), findsNothing);
    },
  );
}
