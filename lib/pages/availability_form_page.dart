import 'package:app_front_mobile/services/availability_service.dart';
import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/widgets/professional_lookup_modal.dart';
import 'package:flutter/material.dart';
import 'package:app_front_mobile/utils/app_message.dart';

class AvailabilityFormPage extends StatefulWidget {
  final String? availabilityId;

  const AvailabilityFormPage({super.key, this.availabilityId});

  bool get isEditing {
    return availabilityId != null && availabilityId!.isNotEmpty;
  }

  @override
  State<AvailabilityFormPage> createState() => _AvailabilityFormPageState();
}

class _AvailabilityFormPageState extends State<AvailabilityFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _availabilityService = AvailabilityService(
    baseUrl: 'http://localhost:8081/availability',
  );

  final _professionalLookupService = ProfessionalLookupService(
    baseUrl: 'http://localhost:8081/professional',
  );

  final _tokenStorage = TokenStorage();

  final _professionalCtrl = TextEditingController();

  final _startTimeCtrl = TextEditingController();

  final _endTimeCtrl = TextEditingController();

  ProfessionalLookupOption? _selectedProfessional;

  String _selectedDay = 'MONDAY';

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _loadingData = false;
  bool _saving = false;

  final List<String> _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadAvailability();
    }
  }

  @override
  void dispose() {
    _professionalCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();

    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingData = true;
    });

    try {
      final token = await _getToken();

      final availability = await _availabilityService.findById(
        token: token,
        id: widget.availabilityId!,
      );

      if (!mounted) return;

      final start = _parseApiTime(availability.startTime);

      final end = _parseApiTime(availability.endTime);

      setState(() {
        _selectedProfessional = ProfessionalLookupOption(
          id: availability.professionalId,
          name: availability.professionalName,
          cpfCnpj: '',
          companyId: availability.companyId,
        );

        _professionalCtrl.text = availability.professionalName;

        _selectedDay = availability.dayWeek;

        _startTime = start;
        _endTime = end;

        _startTimeCtrl.text = start != null ? _formatTime(start) : '';

        _endTimeCtrl.text = end != null ? _formatTime(end) : '';

        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingData = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao carregar disponibilidade',
      );
    }
  }

  Future<void> _openProfessionalLookup() async {
    final token = await _getToken();

    if (!mounted) return;

    final professional = await ProfessionalLookupModal.show(
      context: context,
      token: token,
      service: _professionalLookupService,
    );

    if (professional == null) {
      return;
    }

    setState(() {
      _selectedProfessional = professional;

      _professionalCtrl.text = professional.name;
    });
  }

  Future<void> _selectStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startTime = selected;

      _startTimeCtrl.text = _formatTime(selected);
    });
  }

  Future<void> _selectEndTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 18, minute: 0),
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _endTime = selected;

      _endTimeCtrl.text = _formatTime(selected);
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    if (_selectedProfessional == null) {
      AppMessage.info(context, 'Selecione o profissional');
      return;
    }

    if (_startTime == null || _endTime == null) {
      AppMessage.info(context, 'Informe os horarios');
      return;
    }

    if (!_isEndAfterStart()) {
      AppMessage.info(
        context,
        'Horario final deve ser posterior ao horario inicial',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      final request = AvailabilityRequest(
        professionalId: _selectedProfessional!.id,

        dayWeek: _selectedDay,

        startTime: _timeToApi(_startTime!),

        endTime: _timeToApi(_endTime!),

        companyId: _selectedProfessional!.companyId,
      );

      if (widget.isEditing) {
        await _availabilityService.updateAvailability(
          token: token,
          id: widget.availabilityId!,
          request: request,
        );
      } else {
        await _availabilityService.createAvailability(
          token: token,
          request: request,
        );
      }

      if (!mounted) return;

      AppMessage.success(
        context,
        widget.isEditing
            ? 'Disponibilidade atualizada com sucesso'
            : 'Disponibilidade cadastrada com sucesso',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao salvar disponibilidade.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  bool _isEndAfterStart() {
    if (_startTime == null || _endTime == null) {
      return false;
    }

    final start = _startTime!.hour * 60 + _startTime!.minute;

    final end = _endTime!.hour * 60 + _endTime!.minute;

    return end > start;
  }

  TimeOfDay? _parseApiTime(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');

    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _timeToApi(TimeOfDay value) {
    return '${_formatTime(value)}:00';
  }

  String _dayLabel(String day) {
    return switch (day) {
      'MONDAY' => 'Segunda-feira',
      'TUESDAY' => 'Terca-feira',
      'WEDNESDAY' => 'Quarta-feira',
      'THURSDAY' => 'Quinta-feira',
      'FRIDAY' => 'Sexta-feira',
      'SATURDAY' => 'Sabado',
      'SUNDAY' => 'Domingo',
      _ => day,
    };
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    Widget? suffixIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  Widget _buildProfessionalField() {
    return TextFormField(
      controller: _professionalCtrl,
      readOnly: true,
      onTap: _openProfessionalLookup,
      decoration: _inputDecoration(
        label: 'Profissional',
        hint: 'Selecione o profissional',
        suffixIcon: IconButton(
          onPressed: _openProfessionalLookup,
          icon: const Icon(Icons.search),
        ),
      ),
      validator: (_) {
        if (_selectedProfessional == null) {
          return 'Profissional e obrigatorio';
        }

        return null;
      },
    );
  }

  Widget _buildDayDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDay,
      decoration: _inputDecoration(label: 'Dia da semana'),
      items: _days.map((day) {
        return DropdownMenuItem(value: day, child: Text(_dayLabel(day)));
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedDay = value;
        });
      },
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: _inputDecoration(
        label: label,
        hint: '00:00',
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.access_time),
        ),
      ),
      validator: (value) {
        if ((value ?? '').isEmpty) {
          return '$label e obrigatorio';
        }

        return null;
      },
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loadingData) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                final width = isWide
                    ? (constraints.maxWidth - 14) / 2
                    : constraints.maxWidth;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(width: width, child: _buildProfessionalField()),
                    SizedBox(width: width, child: _buildDayDropdown()),
                    SizedBox(
                      width: width,
                      child: _buildTimeField(
                        controller: _startTimeCtrl,
                        label: 'Horario inicial',
                        onTap: _selectStartTime,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _buildTimeField(
                        controller: _endTimeCtrl,
                        label: 'Horario final',
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                );
              },
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
                      widget.isEditing
                          ? 'Salvar alteracoes'
                          : 'Cadastrar disponibilidade',
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
          widget.isEditing
              ? 'Editar disponibilidade'
              : 'Cadastrar disponibilidade',
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
