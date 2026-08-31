import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:flutter/material.dart';

class BookingConfirmationResult {
  final String notes;

  final bool prefersSilence;

  const BookingConfirmationResult({
    required this.notes,
    required this.prefersSilence,
  });
}

class BookingConfirmationModal extends StatefulWidget {
  final String companyName;

  final PublicCompanyServiceOption service;

  final PublicCompanyProfessional professional;

  final DateTime date;

  final String time;

  const BookingConfirmationModal({
    super.key,
    required this.companyName,
    required this.service,
    required this.professional,
    required this.date,
    required this.time,
  });

  static Future<BookingConfirmationResult?> show({
    required BuildContext context,
    required String companyName,
    required PublicCompanyServiceOption service,
    required PublicCompanyProfessional professional,
    required DateTime date,
    required String time,
  }) {
    return showDialog<BookingConfirmationResult>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.72),
      builder: (_) => BookingConfirmationModal(
        companyName: companyName,
        service: service,
        professional: professional,
        date: date,
        time: time,
      ),
    );
  }

  @override
  State<BookingConfirmationModal> createState() =>
      _BookingConfirmationModalState();
}

class _BookingConfirmationModalState extends State<BookingConfirmationModal> {
  final _notesCtrl = TextEditingController();

  bool _prefersSilence = false;

  @override
  void dispose() {
    _notesCtrl.dispose();

    super.dispose();
  }

  String get _dateText {
    final day = widget.date.day.toString().padLeft(2, '0');

    final month = widget.date.month.toString().padLeft(2, '0');

    return '$day/$month/${widget.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 470),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.storefront, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.companyName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(_dateText),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Divider(color: colorScheme.outline.withOpacity(0.2)),

              const SizedBox(height: 12),

              Text(
                widget.service.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text('Profissional: ${widget.professional.name}'),

              const SizedBox(height: 5),

              Text('${widget.time} · ${widget.service.durationMinutes} min'),

              const SizedBox(height: 5),

              Text(
                'R\$ ${widget.service.price.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Não quero conversar durante o atendimento',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: _prefersSilence,
                  onChanged: (value) {
                    setState(() {
                      _prefersSilence = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alguma observação?',
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      BookingConfirmationResult(
                        notes: _notesCtrl.text.trim(),
                        prefersSilence: _prefersSilence,
                      ),
                    );
                  },
                  child: const Text('Confirmar agendamento'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'O módulo de carrinho será conectado em uma próxima etapa.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Adicionar ao carrinho'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
