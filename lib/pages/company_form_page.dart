import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CompanyFormPage extends StatefulWidget {
  final String? companyId;

  const CompanyFormPage({super.key, this.companyId});

  bool get isEdit => companyId != null && companyId!.trim().isNotEmpty;

  @override
  State<CompanyFormPage> createState() => _CompanyFormPageState();
}

class _CompanyFormPageState extends State<CompanyFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _legalNameCtrl = TextEditingController();

  final _tradeNameCtrl = TextEditingController();

  final _cnpjCtrl = TextEditingController();

  final _imageUrlCtrl = TextEditingController();

  final _zipCodeCtrl = TextEditingController();

  final _streetCtrl = TextEditingController();

  final _numberCtrl = TextEditingController();

  final _districtCtrl = TextEditingController();

  final _cityCtrl = TextEditingController();

  final _complementCtrl = TextEditingController();

  final _instagramCtrl = TextEditingController();

  final _facebookCtrl = TextEditingController();

  final _websiteCtrl = TextEditingController();

  final _tiktokCtrl = TextEditingController();

  final _companyService = CompanyService(
    baseUrl: 'http://localhost:8081/company',
  );

  final _stateService = StateService(baseUrl: 'http://localhost:8081/state');

  final _tokenStorage = TokenStorage();

  bool _loadingInitial = true;
  bool _saving = false;

  String? _selectedType;

  String _selectedStatus = 'ACTIVE';

  StateOption? _selectedState;

  List<CompanyTypeOption> _types = [];

  List<StateOption> _states = [];

  List<String> _statuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED', 'BLOCKED'];

  List<String> _paymentMethods = [];

  List<String> _amenities = [];

  final Set<String> _selectedPaymentMethods = {};

  final Set<String> _selectedAmenities = {};

  final List<CompanyOpeningHourInput> _openingHours = [];

  static const Map<String, String> _days = {
    'MONDAY': 'Segunda-feira',
    'TUESDAY': 'Terça-feira',
    'WEDNESDAY': 'Quarta-feira',
    'THURSDAY': 'Quinta-feira',
    'FRIDAY': 'Sexta-feira',
    'SATURDAY': 'Sábado',
    'SUNDAY': 'Domingo',
  };

  @override
  void initState() {
    super.initState();

    _loadInitialData();
  }

  @override
  void dispose() {
    _legalNameCtrl.dispose();
    _tradeNameCtrl.dispose();
    _cnpjCtrl.dispose();
    _imageUrlCtrl.dispose();

    _zipCodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    _complementCtrl.dispose();

    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _websiteCtrl.dispose();
    _tiktokCtrl.dispose();

    super.dispose();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadInitialData() async {
    try {
      final token = await _token();

      final types = await _companyService.findCompanyTypes();

      final states = await _stateService.findStates();

      final statuses = await _companyService.findCompanyStatuses(token: token);

      final paymentMethods = await _companyService.findPaymentMethods(
        token: token,
      );

      final amenities = await _companyService.findAmenities(token: token);

      CompanyDetail? company;

      if (widget.isEdit) {
        company = await _companyService.findAdminById(
          token: token,
          id: widget.companyId!,
        );
      }

      if (!mounted) return;

      setState(() {
        _types = types;
        _states = states;

        if (statuses.isNotEmpty) {
          _statuses = statuses;
        }

        _paymentMethods = paymentMethods;

        _amenities = amenities;

        if (company != null) {
          _applyCompany(company);
        }

        _loadingInitial = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingInitial = false;
      });

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao carregar os dados da empresa.',
      );
    }
  }

  void _applyCompany(CompanyDetail company) {
    _legalNameCtrl.text = company.legalName;

    _tradeNameCtrl.text = company.tradeName;

    _cnpjCtrl.text = _formatCnpj(company.cnpj);

    _imageUrlCtrl.text = company.imageUrl;

    _zipCodeCtrl.text = _formatCep(company.zipCode);

    _streetCtrl.text = company.street;

    _numberCtrl.text = company.number;

    _districtCtrl.text = company.district;

    _cityCtrl.text = company.city;

    _complementCtrl.text = company.complement;

    _instagramCtrl.text = company.instagramUrl;

    _facebookCtrl.text = company.facebookUrl;

    _websiteCtrl.text = company.websiteUrl;

    _tiktokCtrl.text = company.tiktokUrl;

    _selectedType = company.type.isEmpty ? null : company.type;

    _selectedStatus = company.status.isEmpty ? 'ACTIVE' : company.status;

    _selectedPaymentMethods
      ..clear()
      ..addAll(company.paymentMethods);

    _selectedAmenities
      ..clear()
      ..addAll(company.amenities);

    _openingHours
      ..clear()
      ..addAll(company.openingHours);

    _selectedState = null;

    for (final state in _states) {
      if (state.abbreviation.toUpperCase() == company.state.toUpperCase()) {
        _selectedState = state;

        break;
      }
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    final openingHourError = _validateOpeningHours();

    if (openingHourError != null) {
      AppMessage.info(context, openingHourError);

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _token();

      final request = CompanySaveRequest(
        legalName: _legalNameCtrl.text.trim(),

        tradeName: _tradeNameCtrl.text.trim(),

        cnpj: onlyAlphanumeric(_cnpjCtrl.text),

        type: _selectedType ?? '',

        status: _selectedStatus,

        imageUrl: _imageUrlCtrl.text.trim(),

        zipCode: onlyNumbers(_zipCodeCtrl.text),

        street: _streetCtrl.text.trim(),

        number: _numberCtrl.text.trim(),

        district: _districtCtrl.text.trim(),

        city: _cityCtrl.text.trim(),

        state: _selectedState?.abbreviation ?? '',

        complement: _complementCtrl.text.trim(),

        instagramUrl: _instagramCtrl.text.trim(),

        facebookUrl: _facebookCtrl.text.trim(),

        websiteUrl: _websiteCtrl.text.trim(),

        tiktokUrl: _tiktokCtrl.text.trim(),

        paymentMethods: _selectedPaymentMethods.toList(),

        amenities: _selectedAmenities.toList(),

        openingHours: List.of(_openingHours),
      );

      if (widget.isEdit) {
        await _companyService.updateCompany(
          token: token,
          id: widget.companyId!,
          request: request,
        );
      } else {
        await _companyService.createCompany(token: token, request: request);
      }

      if (!mounted) return;

      AppMessage.success(
        context,
        widget.isEdit
            ? 'Empresa atualizada com sucesso.'
            : 'Empresa cadastrada com sucesso.',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(
        context,
        e,
        fallback: widget.isEdit
            ? 'Erro ao atualizar empresa.'
            : 'Erro ao cadastrar empresa.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String? _validateOpeningHours() {
    final Map<String, List<CompanyOpeningHourInput>> grouped = {};

    for (final hour in _openingHours) {
      final start = _timeToMinutes(hour.startTime);

      final end = _timeToMinutes(hour.endTime);

      if (start == null || end == null) {
        return 'Existe um horário de funcionamento inválido.';
      }

      if (start >= end) {
        return 'O horário inicial deve ser menor que o horário final.';
      }

      grouped.putIfAbsent(hour.dayWeek, () => []).add(hour);
    }

    for (final entry in grouped.entries) {
      final intervals = List<CompanyOpeningHourInput>.from(entry.value);

      intervals.sort(
        (a, b) => (_timeToMinutes(a.startTime) ?? 0).compareTo(
          _timeToMinutes(b.startTime) ?? 0,
        ),
      );

      for (int i = 1; i < intervals.length; i++) {
        final previousEnd = _timeToMinutes(intervals[i - 1].endTime);

        final currentStart = _timeToMinutes(intervals[i].startTime);

        if (previousEnd != null &&
            currentStart != null &&
            currentStart < previousEnd) {
          final dayLabel = _days[entry.key] ?? entry.key;

          return 'Existem horários sobrepostos em $dayLabel.';
        }
      }
    }

    return null;
  }

  int? _timeToMinutes(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);

    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    return hour * 60 + minute;
  }

  void _addOpeningHour(String day) {
    setState(() {
      _openingHours.add(
        CompanyOpeningHourInput(
          dayWeek: day,
          startTime: '09:00',
          endTime: '18:00',
        ),
      );
    });
  }

  Future<String?> _selectTime(String current) async {
    final parts = current.split(':');

    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;

    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (selected == null) {
      return null;
    }

    return '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
  }

  String _paymentLabel(String value) {
    switch (value) {
      case 'CASH':
        return 'Dinheiro';

      case 'PIX':
        return 'PIX';

      case 'BANK_TRANSFER':
        return 'Transferência bancária';

      case 'CREDIT_CARD':
        return 'Cartão de crédito';

      case 'DEBIT_CARD':
        return 'Cartão de débito';

      default:
        return value;
    }
  }

  String _amenityLabel(String value) {
    switch (value) {
      case 'WIFI':
        return 'Wi-fi';

      case 'PARKING':
        return 'Estacionamento';

      case 'ACCESSIBILITY':
        return 'Acessibilidade';

      case 'CHILD_FRIENDLY':
        return 'Atende crianças';

      case 'AIR_CONDITIONING':
        return 'Ar-condicionado';

      case 'PET_FRIENDLY':
        return 'Pet friendly';

      default:
        return value;
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'ACTIVE':
        return 'Ativa';

      case 'INACTIVE':
        return 'Inativa';

      case 'SUSPENDED':
        return 'Suspensa';

      case 'BLOCKED':
        return 'Bloqueada';

      default:
        return value;
    }
  }

  String _formatCnpj(String value) {
    final clean = onlyAlphanumeric(value);

    if (clean.length != 14) {
      return value;
    }

    return '${clean.substring(0, 2)}.'
        '${clean.substring(2, 5)}.'
        '${clean.substring(5, 8)}/'
        '${clean.substring(8, 12)}-'
        '${clean.substring(12, 14)}';
  }

  String _formatCep(String value) {
    final clean = onlyNumbers(value);

    if (clean.length != 8) {
      return value;
    }

    return '${clean.substring(0, 5)}-'
        '${clean.substring(5, 8)}';
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1C212B)
          : colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.45)),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _inputDecoration(label: label, hint: hint),
      validator: (value) {
        final text = (value ?? '').trim();

        if (requiredField && text.isEmpty) {
          return '$label e obrigatorio';
        }

        if (customValidator != null) {
          return customValidator(text);
        }

        return null;
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildSectionTitle(title), ...children],
      ),
    );
  }

  Widget _buildResponsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        final width = isWide
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: fields.map((field) {
            return SizedBox(width: width, child: field);
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompanyTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      decoration: _inputDecoration(label: 'Tipo'),
      items: _types.map((type) {
        return DropdownMenuItem<String>(
          value: type.code,
          child: Text(type.label),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedType = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tipo e obrigatorio';
        }

        return null;
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _inputDecoration(label: 'Status'),
      items: _statuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(_statusLabel(status)),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<StateOption>(
      value: _selectedState,
      decoration: _inputDecoration(label: 'UF'),
      items: _states.map((state) {
        return DropdownMenuItem<StateOption>(
          value: state,
          child: Text(state.label),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedState = value;
        });
      },
      validator: (value) {
        if (value == null || value.abbreviation.isEmpty) {
          return 'UF e obrigatoria';
        }

        return null;
      },
    );
  }

  Widget _buildPaymentMethodsSection() {
    if (_paymentMethods.isEmpty) {
      return const Text('Nenhuma forma de pagamento disponível.');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _paymentMethods.map((method) {
        final selected = _selectedPaymentMethods.contains(method);

        return FilterChip(
          selected: selected,
          label: Text(_paymentLabel(method)),
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedPaymentMethods.add(method);
              } else {
                _selectedPaymentMethods.remove(method);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAmenitiesSection() {
    if (_amenities.isEmpty) {
      return const Text('Nenhuma comodidade disponível.');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _amenities.map((amenity) {
        final selected = _selectedAmenities.contains(amenity);

        return FilterChip(
          selected: selected,
          label: Text(_amenityLabel(amenity)),
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedAmenities.add(amenity);
              } else {
                _selectedAmenities.remove(amenity);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildOpeningHoursEditor() {
    return Column(
      children: _days.entries.map((entry) {
        final intervals = _openingHours
            .where((item) => item.dayWeek == entry.key)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _addOpeningHour(entry.key),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar intervalo'),
                  ),
                ],
              ),

              if (intervals.isEmpty)
                Text(
                  'Fechado',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),

              ...intervals.map((interval) => _buildOpeningHourRow(interval)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOpeningHourRow(CompanyOpeningHourInput interval) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final value = await _selectTime(interval.startTime);

              if (value == null || !mounted) {
                return;
              }

              final index = _openingHours.indexOf(interval);

              if (index < 0) {
                return;
              }

              setState(() {
                _openingHours[index] = CompanyOpeningHourInput(
                  dayWeek: interval.dayWeek,
                  startTime: value,
                  endTime: interval.endTime,
                );
              });
            },
            icon: const Icon(Icons.schedule, size: 17),
            label: Text(_displayTime(interval.startTime)),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('até'),
          ),

          OutlinedButton.icon(
            onPressed: () async {
              final value = await _selectTime(interval.endTime);

              if (value == null || !mounted) {
                return;
              }

              final index = _openingHours.indexOf(interval);

              if (index < 0) {
                return;
              }

              setState(() {
                _openingHours[index] = CompanyOpeningHourInput(
                  dayWeek: interval.dayWeek,
                  startTime: interval.startTime,
                  endTime: value,
                );
              });
            },
            icon: const Icon(Icons.schedule, size: 17),
            label: Text(_displayTime(interval.endTime)),
          ),

          const SizedBox(width: 8),

          IconButton(
            tooltip: 'Remover intervalo',
            onPressed: () {
              setState(() {
                _openingHours.remove(interval);
              });
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }

  String _displayTime(String value) {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Empresa' : 'Cadastro de Empresa'),
      ),
      body: _loadingInitial
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFormCard(
                          title: 'Dados principais',
                          children: [
                            _buildResponsiveFields([
                              _buildTextField(
                                controller: _legalNameCtrl,
                                label: 'Razao social',
                                requiredField: true,
                              ),
                              _buildTextField(
                                controller: _tradeNameCtrl,
                                label: 'Nome fantasia',
                                requiredField: true,
                              ),
                              _buildTextField(
                                controller: _cnpjCtrl,
                                label: 'CNPJ',
                                hint: '00.000.000/0000-00',
                                requiredField: true,
                                inputFormatters: [
                                  CnpjAlphanumericInputFormatter(),
                                ],
                                customValidator: (value) {
                                  final cleanValue = onlyAlphanumeric(value);

                                  if (cleanValue.length != 14) {
                                    return 'CNPJ deve ter 14 caracteres';
                                  }

                                  return null;
                                },
                              ),
                              _buildCompanyTypeDropdown(),
                              _buildStatusDropdown(),
                            ]),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Imagem',
                          children: [
                            _buildTextField(
                              controller: _imageUrlCtrl,
                              label: 'URL da imagem',
                              hint: 'https://...',
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Endereco',
                          children: [
                            _buildResponsiveFields([
                              _buildTextField(
                                controller: _zipCodeCtrl,
                                label: 'CEP',
                                hint: '00000-000',
                                inputFormatters: [CepInputFormatter()],
                                customValidator: (value) {
                                  final cleanValue = onlyNumbers(value);

                                  if (cleanValue.isNotEmpty &&
                                      cleanValue.length != 8) {
                                    return 'CEP deve ter 8 digitos';
                                  }

                                  return null;
                                },
                              ),
                              _buildTextField(
                                controller: _streetCtrl,
                                label: 'Rua',
                              ),
                              _buildTextField(
                                controller: _numberCtrl,
                                label: 'Numero',
                              ),
                              _buildTextField(
                                controller: _districtCtrl,
                                label: 'Bairro',
                              ),
                              _buildTextField(
                                controller: _cityCtrl,
                                label: 'Cidade',
                              ),
                              _buildStateDropdown(),
                            ]),
                            const SizedBox(height: 14),
                            _buildTextField(
                              controller: _complementCtrl,
                              label: 'Complemento',
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Formas de pagamento',
                          children: [_buildPaymentMethodsSection()],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Comodidades',
                          children: [_buildAmenitiesSection()],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Horário de funcionamento',
                          children: [
                            Text(
                              'Adicione uma ou mais faixas de horário para cada dia. Dias sem intervalos serão considerados fechados.',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.62),
                              ),
                            ),

                            const SizedBox(height: 18),

                            _buildOpeningHoursEditor(),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _buildFormCard(
                          title: 'Redes sociais',
                          children: [
                            _buildResponsiveFields([
                              _buildTextField(
                                controller: _instagramCtrl,
                                label: 'Instagram',
                              ),
                              _buildTextField(
                                controller: _facebookCtrl,
                                label: 'Facebook',
                              ),
                              _buildTextField(
                                controller: _websiteCtrl,
                                label: 'Website',
                              ),
                              _buildTextField(
                                controller: _tiktokCtrl,
                                label: 'TikTok',
                              ),
                            ]),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _saving ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                                    widget.isEdit
                                        ? 'Salvar alterações'
                                        : 'Cadastrar empresa',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
