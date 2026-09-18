import 'package:app_front_mobile/pages/appointment_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for the toolbar buttons: Inserir/Editar/Cancelar/
/// Filtros used to render with Material 3's default fully-rounded
/// (StadiumBorder) shape because no explicit `shape` was set, while every
/// other cadastro screen (clients, professionals, users) uses a square
/// 8px-radius shape. This pins the square shape so the two don't drift
/// apart again.
void main() {
  // AppointmentManagementPage isn't built for dependency injection, so
  // initState's _load() makes a real TokenStorage call. Stub the channel to
  // return null quickly so the widget-test environment doesn't hang on an
  // unmocked flutter_secure_storage MethodChannel (queued in the channel
  // buffers with no handler, rather than rejected).
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

  RoundedRectangleBorder? squareShapeOf(WidgetTester tester, Type buttonType, String label) {
    final finder = find.widgetWithText(buttonType, label);
    final style = switch (buttonType) {
      const (FilledButton) => tester.widget<FilledButton>(finder).style,
      const (OutlinedButton) => tester.widget<OutlinedButton>(finder).style,
      _ => throw ArgumentError('Unsupported button type: $buttonType'),
    };

    final shape = style?.shape?.resolve(<WidgetState>{});
    return shape is RoundedRectangleBorder ? shape : null;
  }

  testWidgets(
    'Inserir, Editar, Cancelar and Filtros use a square 8px-radius shape',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppointmentManagementPage(currentUserRole: 'COMPANY_ADMIN'),
        ),
      );
      await tester.pump();

      for (final entry in {
        FilledButton: ['Inserir', 'Editar', 'Cancelar'],
        OutlinedButton: ['Filtros'],
      }.entries) {
        for (final label in entry.value) {
          final shape = squareShapeOf(tester, entry.key, label);

          expect(
            shape,
            isNotNull,
            reason: '"$label" should have an explicit RoundedRectangleBorder shape',
          );
          expect(
            shape!.borderRadius,
            BorderRadius.circular(8),
            reason: '"$label" should use the same square 8px radius as other cadastro screens',
          );
        }
      }
    },
  );
}
