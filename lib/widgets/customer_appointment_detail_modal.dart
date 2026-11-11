import 'package:app_front_mobile/services/customer_appointment_service.dart';
import 'package:flutter/material.dart';

class CustomerAppointmentDetailModal extends StatelessWidget {
  final CustomerAppointment appointment;

  final Future<void> Function() onCancel;

  /// Opens Google Calendar with the event pre-filled. Null hides the option.
  final Future<void> Function()? onAddToGoogleCalendar;

  /// Downloads the .ics invite (iPhone, Outlook, Android...). Null hides it.
  final Future<void> Function()? onDownloadCalendarFile;

  const CustomerAppointmentDetailModal({
    super.key,
    required this.appointment,
    required this.onCancel,
    this.onAddToGoogleCalendar,
    this.onDownloadCalendarFile,
  });

  static Future<void> show({
    required BuildContext context,
    required CustomerAppointment appointment,
    required Future<void> Function() onCancel,
    Future<void> Function()? onAddToGoogleCalendar,
    Future<void> Function()? onDownloadCalendarFile,
  }) {
    return showDialog(
      context: context,
      builder: (_) => CustomerAppointmentDetailModal(
        appointment: appointment,
        onCancel: onCancel,
        onAddToGoogleCalendar: onAddToGoogleCalendar,
        onDownloadCalendarFile: onDownloadCalendarFile,
      ),
    );
  }

  /// Only upcoming appointments go to a calendar: a cancelled one has
  /// nothing to add and a completed one is in the past.
  bool get _canAddToCalendar =>
      appointment.status == 'SCHEDULED' || appointment.status == 'CONFIRMED';

  String _date(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _time(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detalhes do agendamento',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                appointment.companyName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(_date(appointment.startAt)),

              const SizedBox(height: 18),

              ...appointment.services.map((service) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_time(appointment.startAt)} - ${_time(appointment.endAt)}',
                      ),
                      Text('Profissional: ${appointment.professionalName}'),
                      Text(
                        'R\$ ${service.price.toStringAsFixed(2).replaceAll('.', ',')}',
                      ),
                    ],
                  ),
                );
              }),

              if (appointment.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Observação: ${appointment.notes}'),
              ],

              if (appointment.prefersSilence)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Preferência: atendimento sem conversa.'),
                ),

              const SizedBox(height: 18),

              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${appointment.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (_canAddToCalendar &&
                  (onAddToGoogleCalendar != null ||
                      onDownloadCalendarFile != null)) ...[
                const Text(
                  'Adicionar ao calendário',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (onAddToGoogleCalendar != null)
                      OutlinedButton.icon(
                        onPressed: onAddToGoogleCalendar,
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('Google Agenda'),
                      ),
                    if (onDownloadCalendarFile != null)
                      OutlinedButton.icon(
                        onPressed: onDownloadCalendarFile,
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Outro calendário (.ics)'),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
              ],

              if (appointment.status != 'CANCELLED')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Cancelar agendamento'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
