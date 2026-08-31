import 'package:app_front_mobile/services/customer_appointment_service.dart';
import 'package:app_front_mobile/services/public_company_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/booking_confirmation_modal.dart';
import 'package:flutter/material.dart';

class ServiceBookingModal extends StatefulWidget {
  final String companyId;

  final String companyName;

  final PublicCompanyServiceOption service;

  const ServiceBookingModal({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.service,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String companyId,
    required String companyName,
    required PublicCompanyServiceOption service,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceBookingModal(
        companyId: companyId,
        companyName: companyName,
        service: service,
      ),
    );
  }

  @override
  State<ServiceBookingModal> createState() => _ServiceBookingModalState();
}

class _ServiceBookingModalState extends State<ServiceBookingModal> {
  final _tokenStorage = TokenStorage();

  final _publicCompanyService = PublicCompanyService(
    baseUrl: 'http://localhost:8081/public/company',
  );

  final _appointmentService = CustomerAppointmentService(
    baseUrl: 'http://localhost:8081/appointment',
  );

  late final List<DateTime> _dates;

  late DateTime _selectedDate;

  List<PublicCompanyProfessional> _professionals = [];

  PublicCompanyProfessional? _selectedProfessional;

  List<String> _slots = [];

  bool _loadingProfessionals = true;

  bool _loadingSlots = false;

  String _period = 'ALL';

  @override
  void initState() {
    super.initState();

    final today = DateTime.now();

    _dates = List.generate(
      8,
      (index) => DateTime(
        today.year,
        today.month,
        today.day,
      ).add(Duration(days: index)),
    );

    _selectedDate = _dates.first;

    _loadProfessionals();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadProfessionals() async {
    try {
      final professionals = await _publicCompanyService.findProfessionals(
        companyId: widget.companyId,
      );

      if (!mounted) return;

      setState(() {
        _professionals = professionals;

        _selectedProfessional = professionals.isNotEmpty
            ? professionals.first
            : null;

        _loadingProfessionals = false;
      });

      if (_selectedProfessional != null) {
        await _loadSlots();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingProfessionals = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao carregar profissionais.',
      );
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedProfessional == null) {
      return;
    }

    setState(() {
      _loadingSlots = true;
      _slots = [];
    });

    try {
      final token = await _token();

      final result = await _appointmentService.findAvailableSlots(
        token: token,
        companyId: widget.companyId,
        professionalId: _selectedProfessional!.id,
        serviceId: widget.service.id,
        date: _apiDate(_selectedDate),
      );

      if (!mounted) return;

      setState(() {
        _slots = result;
        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSlots = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar horarios.');
    }
  }

  List<String> get _visibleSlots {
    if (_period == 'ALL') {
      return _slots;
    }

    return _slots.where((slot) {
      final hour = int.tryParse(slot.split(':').first) ?? 0;

      if (_period == 'MORNING') {
        return hour < 12;
      }

      return hour >= 12;
    }).toList();
  }

  Future<void> _selectSlot(String slot) async {
    if (_selectedProfessional == null) {
      return;
    }

    final confirmation = await BookingConfirmationModal.show(
      context: context,
      companyName: widget.companyName,
      service: widget.service,
      professional: _selectedProfessional!,
      date: _selectedDate,
      time: slot,
    );

    if (confirmation == null || !mounted) {
      return;
    }

    try {
      final token = await _token();

      await _appointmentService.create(
        token: token,
        companyId: widget.companyId,
        professionalId: _selectedProfessional!.id,
        serviceId: widget.service.id,
        startAt: _buildStartAt(_selectedDate, slot),
        notes: confirmation.notes,
        prefersSilence: confirmation.prefersSilence,
      );

      if (!mounted) return;

      AppMessage.success(context, 'Agendamento realizado com sucesso');

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao realizar agendamento.',
      );
    }
  }

  String _apiDate(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _buildStartAt(DateTime date, String time) {
    final parts = time.split(':');

    return '${_apiDate(date)}T'
        '${parts[0].padLeft(2, '0')}:'
        '${parts[1].padLeft(2, '0')}:00';
  }

  String _weekDay(DateTime date) {
    const values = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

    return values[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.service.name,
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

              const SizedBox(height: 14),

              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = _dates[index];

                    final selected = date == _selectedDate;

                    return InkWell(
                      onTap: () async {
                        setState(() {
                          _selectedDate = date;
                        });

                        await _loadSlots();
                      },
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(_weekDay(date)),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecione um profissional',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_loadingProfessionals)
                const CircularProgressIndicator()
              else
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _professionals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final professional = _professionals[index];

                      final selected =
                          professional.id == _selectedProfessional?.id;

                      return InkWell(
                        onTap: () async {
                          setState(() {
                            _selectedProfessional = professional;
                          });

                          await _loadSlots();
                        },
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: selected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.person),
                            ),
                            const SizedBox(height: 5),
                            SizedBox(
                              width: 80,
                              child: Text(
                                professional.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 20),

              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _period == 'ALL',
                    onSelected: (_) {
                      setState(() {
                        _period = 'ALL';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text('Manhã'),
                    selected: _period == 'MORNING',
                    onSelected: (_) {
                      setState(() {
                        _period = 'MORNING';
                      });
                    },
                  ),

                  const SizedBox(width: 8),

                  ChoiceChip(
                    label: const Text('Tarde'),
                    selected: _period == 'AFTERNOON',
                    onSelected: (_) {
                      setState(() {
                        _period = 'AFTERNOON';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Expanded(
                child: _loadingSlots
                    ? const Center(child: CircularProgressIndicator())
                    : _visibleSlots.isEmpty
                    ? const Center(child: Text('Nenhum horário disponível'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: _visibleSlots.length,
                        itemBuilder: (context, index) {
                          final slot = _visibleSlots[index];

                          return OutlinedButton(
                            onPressed: () => _selectSlot(slot),
                            child: Text(slot),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
