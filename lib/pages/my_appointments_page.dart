import 'package:app_front_mobile/services/customer_appointment_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/customer_appointment_detail_modal.dart';
import 'package:flutter/material.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
  final _service = CustomerAppointmentService(
    baseUrl: 'http://localhost:8081/appointment',
  );

  final _tokenStorage = TokenStorage();

  bool _loading = true;

  List<CustomerAppointment> _appointments = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _token();

      final result = await _service.findMine(token: token);

      if (!mounted) return;

      setState(() {
        _appointments = result.content;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao carregar agendamentos.',
      );
    }
  }

  Future<void> _details(CustomerAppointment appointment) async {
    await CustomerAppointmentDetailModal.show(
      context: context,
      appointment: appointment,
      onCancel: () async {
        try {
          final token = await _token();

          await _service.cancel(token: token, id: appointment.id);

          if (!mounted) return;

          Navigator.of(context).pop();

          AppMessage.success(context, 'Agendamento cancelado com sucesso');

          await _load();
        } catch (e) {
          if (!mounted) return;

          AppMessage.apiError(
            context,
            e,
            fallback: 'Erro ao cancelar agendamento.',
          );
        }
      },
    );
  }

  String _date(CustomerAppointment appointment) {
    final value = DateTime.tryParse(appointment.startAt);

    if (value == null) {
      return '';
    }

    return value.day.toString().padLeft(2, '0');
  }

  String _month(CustomerAppointment appointment) {
    final value = DateTime.tryParse(appointment.startAt);

    if (value == null) {
      return '';
    }

    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];

    return months[value.month - 1];
  }

  String _time(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return 'Agendado';

      case 'CONFIRMED':
        return 'Confirmado';

      case 'CANCELLED':
        return 'Cancelado';

      case 'COMPLETED':
        return 'Concluído';

      case 'NO_SHOW':
        return 'Não compareceu';

      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return colorScheme.primary;

      case 'CONFIRMED':
        return const Color(0xFF2EAD72);

      case 'CANCELLED':
        return colorScheme.error;

      case 'COMPLETED':
        return const Color(0xFF2EAD72);

      case 'NO_SHOW':
        return const Color(0xFFE09132);

      default:
        return colorScheme.onSurface;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return Icons.schedule_outlined;

      case 'CONFIRMED':
        return Icons.check_circle_outline;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      case 'COMPLETED':
        return Icons.task_alt;

      case 'NO_SHOW':
        return Icons.person_off_outlined;

      default:
        return Icons.info_outline;
    }
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final color = _statusColor(context, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus Agendamentos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _appointments.isEmpty
                ? const Center(
                    child: Text('Você ainda não possui agendamentos.'),
                  )
                : ListView.separated(
                    itemCount: _appointments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _appointments[index];

                      final service = item.services.isNotEmpty
                          ? item.services.first.name
                          : 'Serviço';

                      final isCancelled =
                          item.status.toUpperCase() == 'CANCELLED';

                      final statusColor = _statusColor(context, item.status);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(
                              isCancelled ? 0.35 : 0.12,
                            ),
                          ),
                        ),
                        child: Opacity(
                          opacity: isCancelled ? 0.65 : 1,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: statusColor.withOpacity(0.12),
                                child: Icon(
                                  isCancelled
                                      ? Icons.event_busy_outlined
                                      : Icons.storefront,
                                  color: statusColor,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.companyName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        _buildStatusBadge(context, item.status),
                                      ],
                                    ),

                                    const SizedBox(height: 7),

                                    Text(
                                      'R\$ ${item.totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                                      style: TextStyle(
                                        color: isCancelled
                                            ? colorScheme.onSurface.withOpacity(
                                                0.55,
                                              )
                                            : colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                        decoration: isCancelled
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.design_services_outlined,
                                          size: 15,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.6),
                                        ),

                                        const SizedBox(width: 5),

                                        Expanded(
                                          child: Text(
                                            '$service · ${_time(item.startAt)}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    TextButton(
                                      onPressed: () => _details(item),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 34),
                                      ),
                                      child: const Text('Ver detalhes'),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              Column(
                                children: [
                                  Text(
                                    _date(item),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: isCancelled
                                          ? colorScheme.onSurface.withOpacity(
                                              0.55,
                                            )
                                          : colorScheme.onSurface,
                                    ),
                                  ),

                                  Text(
                                    _month(item),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isCancelled
                                          ? colorScheme.onSurface.withOpacity(
                                              0.45,
                                            )
                                          : colorScheme.onSurface.withOpacity(
                                              0.7,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
