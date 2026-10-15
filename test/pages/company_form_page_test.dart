import 'package:app_front_mobile/pages/company_form_page.dart';
import 'package:app_front_mobile/services/city_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

/// Regression coverage for the company address: CompanyFormPage used a
/// DropdownButtonFormField for UF and a free-text field for Cidade, while
/// the other cadastros (ClientFormPage, ProfessionalFormPage) open the
/// shared StateLookupModal and then CityLookupModal filtered by that UF.
/// This pins the company form to the same pattern.
void main() {
  // Same reason as client_form_page_test.dart: the page builds its own
  // TokenStorage, so the unmocked flutter_secure_storage channel would hang
  // the loading spinner forever. Returning null makes _token() throw, which
  // _loadInitialData already catches, and the form renders.
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

  Future<void> pumpForm(WidgetTester tester) async {
    await useDesktopTestSurface(tester);

    await tester.pumpWidget(testApp(const CompanyFormPage()));

    // pumpAndSettle never settles while the indeterminate spinner is shown.
    for (var i = 0;
        i < 50 && find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'UF and Cidade are search fields that open the shared lookup modal, not dropdowns',
    (tester) async {
      await pumpForm(tester);

      expect(find.byTooltip('Selecionar UF'), findsOneWidget);
      expect(find.byTooltip('Selecionar cidade'), findsOneWidget);

      expect(find.byType(DropdownButtonFormField<StateOption>), findsNothing);
      expect(find.byType(DropdownButtonFormField<CityOption>), findsNothing);
    },
  );

  testWidgets('Cidade stays disabled until a UF is selected', (tester) async {
    await pumpForm(tester);

    expect(find.text('Selecione uma UF primeiro'), findsOneWidget);

    final cityButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Selecionar cidade'),
        matching: find.byType(IconButton),
      ),
    );

    expect(cityButton.onPressed, isNull);
  });
}
