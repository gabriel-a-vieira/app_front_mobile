import 'package:app_front_mobile/services/customer_appointment_service.dart';
import 'package:app_front_mobile/widgets/customer_appointment_detail_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The "Adicionar ao calendário" section: shown only for upcoming
/// appointments, and each button fires its own callback.
void main() {
  CustomerAppointment appointment(String status) => CustomerAppointment(
    id: 'appt-1',
    companyId: 'c-1',
    companyName: 'Studio X',
    professionalName: 'Ana',
    startAt: '2026-12-01T10:00:00',
    endAt: '2026-12-01T10:30:00',
    status: status,
    totalPrice: 50,
    notes: '',
    prefersSilence: false,
    services: const [],
  );

  Future<void> pump(
    WidgetTester tester,
    String status, {
    Future<void> Function()? onGoogle,
    Future<void> Function()? onFile,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerAppointmentDetailModal(
            appointment: appointment(status),
            onCancel: () async {},
            onAddToGoogleCalendar: onGoogle,
            onDownloadCalendarFile: onFile,
          ),
        ),
      ),
    );
  }

  testWidgets('shows both calendar options for a scheduled appointment and fires them', (tester) async {
    var google = 0;
    var file = 0;

    await pump(
      tester,
      'SCHEDULED',
      onGoogle: () async => google++,
      onFile: () async => file++,
    );

    expect(find.text('Adicionar ao calendário'), findsOneWidget);

    await tester.tap(find.text('Google Agenda'));
    await tester.tap(find.text('Outro calendário (.ics)'));

    expect(google, 1);
    expect(file, 1);
  });

  for (final status in ['CANCELLED', 'COMPLETED']) {
    testWidgets('hides the calendar options for a $status appointment', (tester) async {
      await pump(
        tester,
        status,
        onGoogle: () async {},
        onFile: () async {},
      );

      expect(find.text('Adicionar ao calendário'), findsNothing);
      expect(find.text('Google Agenda'), findsNothing);
    });
  }

  testWidgets('hides the calendar options when no callbacks are given', (tester) async {
    await pump(tester, 'CONFIRMED');

    expect(find.text('Adicionar ao calendário'), findsNothing);
  });
}
