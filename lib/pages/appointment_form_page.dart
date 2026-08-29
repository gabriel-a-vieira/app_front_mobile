import 'package:app_front_mobile/services/appointment_service.dart';
import 'package:app_front_mobile/services/client_lookup_service.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:app_front_mobile/services/service_offering_lookup_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/client_lookup_modal.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:app_front_mobile/widgets/professional_lookup_modal.dart';
import 'package:app_front_mobile/widgets/service_offering_lookup_modal.dart';
import 'package:flutter/material.dart';

class AppointmentFormPage extends StatefulWidget {
  final String? appointmentId;
  final String currentUserRole;

  const AppointmentFormPage({
    super.key,
    this.appointmentId,
    required this.currentUserRole,
  });

  bool get isEditing => appointmentId != null && appointmentId!.isNotEmpty;

  bool get isMasterAdmin => currentUserRole.toUpperCase() == 'MASTER_ADMIN';

  @override
  State<AppointmentFormPage> createState() => _AppointmentFormPageState();
}

class _AppointmentFormPageState extends State<AppointmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenStorage = TokenStorage();

  final _appointmentService = AppointmentService(
    baseUrl: 'http://localhost:8081/appointment',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _clientLookupService = ClientLookupService(
    baseUrl: 'http://localhost:8081/client',
  );

  final _professionalLookupService = ProfessionalLookupService(
    baseUrl: 'http://localhost:8081/professional',
  );

  final _serviceLookupService = ServiceOfferingLookupService(
    baseUrl: 'http://localhost:8081/service-offering',
  );

  final _companyCtrl = TextEditingController();

  final _clientCtrl = TextEditingController();

  final _professionalCtrl = TextEditingController();

  final _servicesCtrl = TextEditingController();

  final _dateCtrl = TextEditingController();

  CompanyLookupOption? _selectedCompany;

  ClientLookupOption? _selectedClient;

  ProfessionalLookupOption? _selectedProfessional;

  List<ServiceOfferingLookupOption> _selectedServices = [];

  DateTime? _selectedDate;

  List<String> _availableSlots = [];

  String? _selectedSlot;

  String _selectedStatus = 'SCHEDULED';

  String _loadedCompanyId = '';

  bool _loading = false;
  bool _loadingSlots = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadAppointment();
    }
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _clientCtrl.dispose();
    _professionalCtrl.dispose();
    _servicesCtrl.dispose();
    _dateCtrl.dispose();

    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  String get _effectiveCompanyId {
    if (_selectedCompany != null) {
      return _selectedCompany!.id;
    }

    return _loadedCompanyId;
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      final appointment = await _appointmentService.findById(
        token: token,
        id: widget.appointmentId!,
      );

      final start = DateTime.tryParse(appointment.startAt);

      if (!mounted) return;

      setState(() {
        _loadedCompanyId = appointment.companyId;

        _selectedClient = ClientLookupOption(
          id: appointment.clientId,
          name: appointment.clientName,
          cpfCnpj: '',
          companyId: appointment.companyId,
        );

        _clientCtrl.text = appointment.clientName;

        _selectedProfessional = ProfessionalLookupOption(
          id: appointment.professionalId,
          name: appointment.professionalName,
          cpfCnpj: '',
          companyId: appointment.companyId,
        );

        _professionalCtrl.text = appointment.professionalName;

        _selectedServices = appointment.services.map((item) {
          return ServiceOfferingLookupOption(
            id: item.serviceOfferingId,
            name: item.name,
            durationMinutes: item.durationMinutes,
            price: item.price,
            companyId: appointment.companyId,
          );
        }).toList();

        _updateServicesText();

        if (start != null) {
          _selectedDate = start;

          _dateCtrl.text = _formatDate(start);

          _selectedSlot = _formatTime(start);
        }

        _selectedStatus = appointment.status;

        _loading = false;
      });

      await _loadAvailableSlots(keepCurrentSlot: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao carregar agendamento.',
      );
    }
  }

  Future<void> _openCompanyLookup() async {
    final token = await _getToken();

    if (!mounted) return;

    final company = await CompanyLookupModal.show(
      context: context,
      token: token,
      service: _companyLookupService,
    );

    if (company == null) return;

    setState(() {
      _selectedCompany = company;
      _companyCtrl.text = company.displayName;

      _selectedClient = null;
      _selectedProfessional = null;
      _selectedServices = [];

      _clientCtrl.clear();
      _professionalCtrl.clear();
      _servicesCtrl.clear();

      _selectedSlot = null;
      _availableSlots = [];
    });
  }

  bool _validateCompanySelection() {
    if (widget.isMasterAdmin && _effectiveCompanyId.isEmpty) {
      AppMessage.info(context, 'Selecione uma empresa primeiro.');

      return false;
    }

    return true;
  }

  Future<void> _openClientLookup() async {
    if (!_validateCompanySelection()) {
      return;
    }

    final token = await _getToken();

    if (!mounted) return;

    final client = await ClientLookupModal.show(
      context: context,
      token: token,
      service: _clientLookupService,
      companyId: _effectiveCompanyId,
    );

    if (client == null) return;

    setState(() {
      _selectedClient = client;
      _clientCtrl.text = client.name;
    });
  }

  Future<void> _openProfessionalLookup() async {
    if (!_validateCompanySelection()) {
      return;
    }

    final token = await _getToken();

    if (!mounted) return;

    final professional = await ProfessionalLookupModal.show(
      context: context,
      token: token,
      service: _professionalLookupService,
      companyId: _effectiveCompanyId,
    );

    if (professional == null) return;

    setState(() {
      _selectedProfessional = professional;

      _professionalCtrl.text = professional.name;

      _selectedSlot = null;
      _availableSlots = [];
    });

    await _loadAvailableSlots();
  }

  Future<void> _openServicesLookup() async {
    if (!_validateCompanySelection()) {
      return;
    }

    final token = await _getToken();

    if (!mounted) return;

    final services = await ServiceOfferingLookupModal.show(
      context: context,
      token: token,
      service: _serviceLookupService,
      companyId: _effectiveCompanyId,
      initialSelection: _selectedServices,
    );

    if (services == null) return;

    setState(() {
      _selectedServices = services;

      _updateServicesText();

      _selectedSlot = null;
      _availableSlots = [];
    });

    await _loadAvailableSlots();
  }

  void _updateServicesText() {
    _servicesCtrl.text = _selectedServices
        .map((service) => service.name)
        .join(', ');
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 1),
    );

    if (selected == null) return;

    setState(() {
      _selectedDate = selected;

      _dateCtrl.text = _formatDate(selected);

      _selectedSlot = null;
      _availableSlots = [];
    });

    await _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots({bool keepCurrentSlot = false}) async {
    if (_selectedProfessional == null ||
        _selectedServices.isEmpty ||
        _selectedDate == null) {
      return;
    }

    setState(() {
      _loadingSlots = true;
    });

    try {
      final token = await _getToken();

      final slots = await _appointmentService.findAvailableSlots(
        token: token,
        professionalId: _selectedProfessional!.id,
        date: _apiDate(_selectedDate!),
        serviceIds: _selectedServices.map((service) => service.id).toList(),
        companyId: _effectiveCompanyId,
        ignoreAppointmentId: widget.appointmentId ?? '',
      );

      if (!mounted) return;

      setState(() {
        _availableSlots = slots;

        if (keepCurrentSlot &&
            _selectedSlot != null &&
            !_availableSlots.contains(_selectedSlot)) {
          _availableSlots.insert(0, _selectedSlot!);
        }

        _loadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingSlots = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao buscar horarios disponiveis.',
      );
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    if (_selectedClient == null) {
      AppMessage.info(context, 'Selecione o cliente.');
      return;
    }

    if (_selectedProfessional == null) {
      AppMessage.info(context, 'Selecione o profissional.');
      return;
    }

    if (_selectedServices.isEmpty) {
      AppMessage.info(context, 'Selecione pelo menos um servico.');
      return;
    }

    if (_selectedDate == null || _selectedSlot == null) {
      AppMessage.info(context, 'Selecione a data e o horario.');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      final request = AppointmentRequest(
        clientId: _selectedClient!.id,

        professionalId: _selectedProfessional!.id,

        startAt: _buildStartAt(),

        serviceIds: _selectedServices.map((service) => service.id).toList(),

        companyId: _effectiveCompanyId,

        status: widget.isEditing ? _selectedStatus : null,
      );

      if (widget.isEditing) {
        await _appointmentService.updateAppointment(
          token: token,
          id: widget.appointmentId!,
          request: request,
        );
      } else {
        await _appointmentService.createAppointment(
          token: token,
          request: request,
        );
      }

      if (!mounted) return;

      AppMessage.success(
        context,
        widget.isEditing
            ? 'Agendamento atualizado com sucesso'
            : 'Agendamento realizado com sucesso',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar agendamento.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _buildStartAt() {
    final parts = _selectedSlot!.split(':');

    final hour = int.parse(parts[0]);

    final minute = int.parse(parts[1]);

    final value = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}T'
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:00';
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }

  String _apiDate(DateTime value) {
    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  int get _totalDuration {
    return _selectedServices.fold(
      0,
      (total, service) => total + service.durationMinutes,
    );
  }

  double get _totalPrice {
    return _selectedServices.fold(0, (total, service) => total + service.price);
  }

  InputDecoration _decoration({required String label, Widget? suffixIcon}) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1C212B)
          : colorScheme.surfaceContainerHighest,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    );
  }

  Widget _lookupField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _decoration(
        label: label,
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildSlots() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_selectedDate == null ||
        _selectedProfessional == null ||
        _selectedServices.isEmpty) {
      return Text(
        'Selecione profissional, servico e data para visualizar os horarios.',
        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
      );
    }

    if (_availableSlots.isEmpty) {
      return Text(
        'Nenhum horario disponivel nesta data.',
        style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w600),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSlots.map((slot) {
        final selected = _selectedSlot == slot;

        return ChoiceChip(
          label: Text(slot),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedSlot = slot;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
            ),
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 760;

                    final width = isWide
                        ? (constraints.maxWidth - 14) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        if (widget.isMasterAdmin && !widget.isEditing)
                          SizedBox(
                            width: width,
                            child: _lookupField(
                              controller: _companyCtrl,
                              label: 'Empresa',
                              onTap: _openCompanyLookup,
                            ),
                          ),

                        SizedBox(
                          width: width,
                          child: _lookupField(
                            controller: _clientCtrl,
                            label: 'Cliente',
                            onTap: _openClientLookup,
                          ),
                        ),

                        SizedBox(
                          width: width,
                          child: _lookupField(
                            controller: _professionalCtrl,
                            label: 'Profissional',
                            onTap: _openProfessionalLookup,
                          ),
                        ),

                        SizedBox(
                          width: width,
                          child: _lookupField(
                            controller: _servicesCtrl,
                            label: 'Servicos',
                            onTap: _openServicesLookup,
                          ),
                        ),

                        SizedBox(
                          width: width,
                          child: TextFormField(
                            controller: _dateCtrl,
                            readOnly: true,
                            onTap: _selectDate,
                            decoration: _decoration(
                              label: 'Data',
                              suffixIcon: IconButton(
                                onPressed: _selectDate,
                                icon: const Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ),
                        ),

                        if (widget.isEditing)
                          SizedBox(
                            width: width,
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: _decoration(label: 'Status'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'SCHEDULED',
                                  child: Text('Agendado'),
                                ),
                                DropdownMenuItem(
                                  value: 'CONFIRMED',
                                  child: Text('Confirmado'),
                                ),
                                DropdownMenuItem(
                                  value: 'CANCELLED',
                                  child: Text('Cancelado'),
                                ),
                                DropdownMenuItem(
                                  value: 'COMPLETED',
                                  child: Text('Concluido'),
                                ),
                                DropdownMenuItem(
                                  value: 'NO_SHOW',
                                  child: Text('Nao compareceu'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }

                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),

                if (_selectedServices.isNotEmpty) ...[
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Text('Duracao total: $_totalDuration min'),
                      const SizedBox(width: 20),
                      Text(
                        'Valor total: R\$ ${_totalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Horarios disponiveis',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Align(alignment: Alignment.centerLeft, child: _buildSlots()),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      widget.isEditing ? 'Salvar alteracoes' : 'Agendar',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Editar agendamento' : 'Novo agendamento',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
}
