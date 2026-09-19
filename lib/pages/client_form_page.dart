import 'package:app_front_mobile/services/city_service.dart';
import 'package:app_front_mobile/services/client_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:app_front_mobile/widgets/city_lookup_modal.dart';
import 'package:app_front_mobile/widgets/state_lookup_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:app_front_mobile/services/user_lookup_service.dart';
import 'package:app_front_mobile/widgets/user_lookup_modal.dart';
import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/theme/app_colors.dart';

class ClientFormPage extends StatefulWidget {
  final String? clientId;
  final String currentUserRole;

  const ClientFormPage({
    super.key,
    this.clientId,
    required this.currentUserRole,
  });

  bool get isEdit {
    return clientId != null && clientId!.isNotEmpty;
  }

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenStorage = TokenStorage();

  final _clientService = ClientService(baseUrl: '${ApiConfig.baseUrl}/client');

  final _stateService = StateService(baseUrl: '${ApiConfig.baseUrl}/state');

  final _cityService = CityService(baseUrl: '${ApiConfig.baseUrl}/city');

  final _companyLookupService = CompanyLookupService(
    baseUrl: '${ApiConfig.baseUrl}/company/companies/home-page',
  );

  final _userLookupService = UserLookupService(
    baseUrl: '${ApiConfig.baseUrl}/users',
  );

  final _nameController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  final _companyController = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _linkedUserCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _loadingCities = false;

  DateTime? _selectedBirthDate;

  String _selectedGender = 'MASCULINO';
  String _selectedStatus = 'ACTIVE';
  String _selectedPaymentMethod = '';

  List<String> _paymentMethods = [];
  List<StateOption> _states = [];

  StateOption? _selectedState;
  CityOption? _selectedCity;
  CompanyLookupOption? _selectedCompany;
  UserLookupOption? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfCnpjController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _postalCodeController.dispose();
    _complementController.dispose();
    _neighborhoodController.dispose();
    _additionalNotesController.dispose();
    _companyController.dispose();
    _stateCtrl.dispose();
    _cityCtrl.dispose();
    _linkedUserCtrl.dispose();

    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      final states = await _stateService.findStates();
      final paymentMethods = await _clientService.findPaymentMethods(
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _states = states;
        _paymentMethods = paymentMethods;
      });

      if (widget.isEdit) {
        await _loadClient(token);
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar dados.');
    }
  }

  Future<void> _loadClient(String token) async {
    final client = await _clientService.findById(
      token: token,
      id: widget.clientId!,
    );

    _nameController.text = client.name;
    _cpfCnpjController.text = _formatCpf(client.cpfCnpj);
    _phoneController.text = _formatPhone(client.phone);
    _postalCodeController.text = _formatCep(client.postalCode);
    _streetController.text = client.street;
    _numberController.text = client.number;
    _complementController.text = client.complement;
    _neighborhoodController.text = client.neighborhood;
    _additionalNotesController.text = client.additionalNotes;

    _selectedGender = client.gender.isNotEmpty ? client.gender : 'MASCULINO';
    _selectedStatus = client.status.isNotEmpty ? client.status : 'ACTIVE';
    _selectedPaymentMethod = client.preferredPaymentMethod;

    if (client.birthDate.isNotEmpty) {
      _selectedBirthDate = DateTime.tryParse(client.birthDate);
      if (_selectedBirthDate != null) {
        _birthDateController.text = _formatDate(_selectedBirthDate!);
      }
    }

    if (client.companyId.isNotEmpty) {
      _companyController.text = client.companyId;
    }

    if (client.userId.isNotEmpty) {
      _selectedUser = UserLookupOption(
        id: client.userId,
        name: client.userName,
        email: client.userEmail,
        role: 'CLIENT',
      );
      _linkedUserCtrl.text = client.userName;
    }

    if (client.state.isNotEmpty) {
      final state = _findStateByAbbreviation(client.state);

      if (state != null) {
        _selectedState = state;
        _stateCtrl.text = state.label;
        await _loadCitiesByState(
          state.abbreviation,
          selectedCityId: client.cityId,
        );
      }
    }
  }

  StateOption? _findStateByAbbreviation(String abbreviation) {
    for (final state in _states) {
      if (state.abbreviation.toUpperCase() == abbreviation.toUpperCase()) {
        return state;
      }
    }

    return null;
  }

  CityOption? _findCityById(List<CityOption> cities, String id) {
    for (final city in cities) {
      if (city.id == id) {
        return city;
      }
    }

    return null;
  }

  Future<void> _loadCitiesByState(
    String state, {
    String? selectedCityId,
  }) async {
    if (state.isEmpty) return;

    setState(() {
      _loadingCities = true;
      _selectedCity = null;
      _cityCtrl.clear();
    });

    try {
      final cities = await _cityService.findByState(state: state);

      if (!mounted) return;

      setState(() {
        _selectedCity = selectedCityId != null && selectedCityId.isNotEmpty
            ? _findCityById(cities, selectedCityId)
            : null;
        _cityCtrl.text = _selectedCity?.name ?? '';
        _loadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingCities = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar cidades.');
    }
  }

  Future<void> _openCompanyZoom() async {
    if (widget.isEdit) {
      return;
    }

    final token = await _tokenStorage.getAccessToken();

    final company = await CompanyLookupModal.show(
      context: context,
      token: token,
      service: _companyLookupService,
    );

    if (company == null) return;

    setState(() {
      _selectedCompany = company;
      _companyController.text = company.displayName;
    });
  }

  Future<void> _openUserZoom() async {
    final token = await _tokenStorage.getAccessToken();

    final user = await UserLookupModal.show(
      context: context,
      token: token ?? '',
      service: _userLookupService,
    );

    if (user == null) return;

    setState(() {
      _selectedUser = user;
      _linkedUserCtrl.text = user.name;
    });
  }

  void _clearUserLink() {
    setState(() {
      _selectedUser = null;
      _linkedUserCtrl.clear();
    });
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 18),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) return;

    setState(() {
      _selectedBirthDate = selectedDate;
      _birthDateController.text = _formatDate(selectedDate);
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    if (_selectedCity == null) {
      AppMessage.info(context, 'Selecione a cidade');
      return;
    }

    if (widget.isMasterAdmin && !widget.isEdit && _selectedCompany == null) {
      AppMessage.info(context, 'Selecione a empresa');
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      final request = ClientRequest(
        name: _nameController.text.trim(),
        cpfCnpj: onlyNumbers(_cpfCnpjController.text),
        phone: onlyNumbers(_phoneController.text),
        birthDate: _selectedBirthDate != null
            ? _dateToRequest(_selectedBirthDate!)
            : '',
        gender: _selectedGender,
        preferredPaymentMethod: _selectedPaymentMethod,
        additionalNotes: _additionalNotesController.text.trim(),
        status: _selectedStatus,
        companyId: widget.isMasterAdmin && !widget.isEdit
            ? _selectedCompany?.id ?? ''
            : '',
        cityId: _selectedCity?.id ?? '',
        city: _selectedCity?.name ?? '',
        state: _selectedState?.abbreviation ?? '',
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        postalCode: onlyNumbers(_postalCodeController.text),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        userId: _selectedUser?.id,
      );

      if (widget.isEdit) {
        await _clientService.updateClient(
          token: token,
          id: widget.clientId!,
          request: request,
        );
      } else {
        await _clientService.createClient(token: token, request: request);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar cliente.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _formatCpf(String value) {
    final digits = onlyNumbers(value);

    if (digits.length != 11) {
      return value;
    }

    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9, 11)}';
  }

  String _formatPhone(String value) {
    final digits = onlyNumbers(value);

    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }

    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return value;
  }

  String _formatCep(String value) {
    final digits = onlyNumbers(value);

    if (digits.length != 8) {
      return value;
    }

    return '${digits.substring(0, 5)}-${digits.substring(5)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _dateToRequest(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$year-$month-$day';
  }

  String _formatOption(String value) {
    return switch (value.toUpperCase()) {
      'ACTIVE' => 'Ativo',
      'INACTIVE' => 'Inativo',
      'MASCULINO' => 'Masculino',
      'FEMININO' => 'Feminino',
      'OUTRO' => 'Outro',
      'PIX' => 'PIX',
      'CASH' => 'Dinheiro',
      'CREDIT_CARD' => 'Cartao de credito',
      'DEBIT_CARD' => 'Cartao de debito',
      _ => value.replaceAll('_', ' '),
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
          ? AppColors.darkInputFill
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
    bool readOnly = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? customValidator,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onTap: onTap,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        suffixIcon: suffixIcon,
      ),
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

  Future<void> _selectState() async {
    final selected = await StateLookupModal.show(
      context: context,
      states: _states,
      selectedState: _selectedState,
    );

    if (selected == null || !mounted) {
      return;
    }

    final changedState =
        _selectedState?.abbreviation.toUpperCase() !=
        selected.abbreviation.toUpperCase();

    setState(() {
      _selectedState = selected;
      _stateCtrl.text = selected.label;
    });

    if (changedState) {
      await _loadCitiesByState(selected.abbreviation);
    }
  }

  Future<void> _selectCity() async {
    final state = _selectedState;

    if (state == null) {
      AppMessage.info(context, 'Selecione primeiro a UF.');

      return;
    }

    final selected = await CityLookupModal.show(
      context: context,
      service: _cityService,
      state: state,
      selectedCity: _selectedCity,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedCity = selected;
      _cityCtrl.text = selected.name;
    });
  }

  Widget _buildStateField() {
    return TextFormField(
      controller: _stateCtrl,
      readOnly: true,
      onTap: _selectState,
      decoration: _inputDecoration(
        label: 'UF',
        hint: 'Selecione a UF',
        suffixIcon: IconButton(
          tooltip: 'Selecionar UF',
          onPressed: _selectState,
          icon: const Icon(Icons.search),
        ),
      ),
      validator: (_) {
        if (_selectedState == null || _selectedState!.abbreviation.isEmpty) {
          return 'UF e obrigatoria';
        }

        return null;
      },
    );
  }

  Widget _buildCityField() {
    return TextFormField(
      controller: _cityCtrl,
      readOnly: true,
      onTap: _selectCity,
      decoration: _inputDecoration(
        label: 'Cidade',
        hint: _selectedState == null
            ? 'Selecione uma UF primeiro'
            : _loadingCities
            ? 'Carregando cidades...'
            : 'Selecione a cidade',
        suffixIcon: IconButton(
          tooltip: 'Selecionar cidade',
          onPressed: _selectedState == null ? null : _selectCity,
          icon: const Icon(Icons.search),
        ),
      ),
      validator: (_) {
        if (_selectedCity == null || _selectedCity!.id.isEmpty) {
          return 'Cidade e obrigatoria';
        }

        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: _inputDecoration(label: 'Genero'),
      items: const [
        DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
        DropdownMenuItem(value: 'FEMININO', child: Text('Feminino')),
        DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: _inputDecoration(label: 'Status'),
      items: const [
        DropdownMenuItem(value: 'ACTIVE', child: Text('Ativo')),
        DropdownMenuItem(value: 'INACTIVE', child: Text('Inativo')),
      ],
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildPaymentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: _inputDecoration(label: 'Forma de pagamento preferida'),
      items: [
        const DropdownMenuItem(value: '', child: Text('Nao informado')),
        ..._paymentMethods.map((method) {
          return DropdownMenuItem(
            value: method,
            child: Text(_formatOption(method)),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value ?? '';
        });
      },
    );
  }

  Widget _buildCompanyField() {
    if (!widget.isMasterAdmin) {
      return const SizedBox.shrink();
    }

    return _buildTextField(
      controller: _companyController,
      label: 'Empresa',
      hint: widget.isEdit ? 'Empresa atual' : 'Selecione a empresa',
      readOnly: true,
      requiredField: !widget.isEdit,
      onTap: widget.isEdit ? null : _openCompanyZoom,
      suffixIcon: widget.isEdit
          ? null
          : IconButton(
              onPressed: _openCompanyZoom,
              icon: const Icon(Icons.search),
            ),
    );
  }

  Widget _buildUserField() {
    return _buildTextField(
      controller: _linkedUserCtrl,
      label: 'Usuario vinculado',
      hint: 'Selecione um usuario existente (opcional)',
      readOnly: true,
      onTap: _openUserZoom,
      suffixIcon: _selectedUser != null
          ? IconButton(onPressed: _clearUserLink, icon: const Icon(Icons.close))
          : IconButton(onPressed: _openUserZoom, icon: const Icon(Icons.search)),
    );
  }

  Widget _buildFormCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.22)),
      ),
      child: Form(
        key: _formKey,
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
                if (widget.isMasterAdmin)
                  SizedBox(width: width, child: _buildCompanyField()),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _nameController,
                    label: 'Nome',
                    requiredField: true,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _cpfCnpjController,
                    label: 'CPF',
                    hint: '000.000.000-00',
                    requiredField: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_CpfInputFormatter()],
                    customValidator: (value) {
                      final digits = onlyNumbers(value);

                      if (digits.length != 11) {
                        return 'CPF deve ter 11 digitos';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    hint: '(00) 00000-0000',
                    requiredField: true,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [_PhoneInputFormatter()],
                    customValidator: (value) {
                      final digits = onlyNumbers(value);

                      if (digits.length < 10 || digits.length > 11) {
                        return 'Telefone invalido';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _birthDateController,
                    label: 'Data de nascimento',
                    hint: 'dd/mm/aaaa',
                    readOnly: true,
                    onTap: _selectBirthDate,
                    suffixIcon: IconButton(
                      onPressed: _selectBirthDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  ),
                ),
                SizedBox(width: width, child: _buildGenderDropdown()),
                SizedBox(width: width, child: _buildPaymentDropdown()),
                SizedBox(width: width, child: _buildStatusDropdown()),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _postalCodeController,
                    label: 'CEP',
                    hint: '00000-000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [CepInputFormatter()],
                    customValidator: (value) {
                      final digits = onlyNumbers(value);

                      if (digits.isNotEmpty && digits.length != 8) {
                        return 'CEP deve ter 8 digitos';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _streetController,
                    label: 'Rua',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _numberController,
                    label: 'Numero',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _neighborhoodController,
                    label: 'Bairro',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _complementController,
                    label: 'Complemento',
                  ),
                ),
                SizedBox(width: width, child: _buildStateField()),
                SizedBox(width: width, child: _buildCityField()),
                SizedBox(width: width, child: _buildUserField()),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildTextField(
                    controller: _additionalNotesController,
                    label: 'Observacoes',
                    maxLines: 4,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEdit ? 'Editar cliente' : 'Cadastro de cliente',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isEdit
              ? 'Atualize os dados do cliente'
              : 'Cadastre um novo cliente no sistema',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.65),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 22),
        _buildFormCard(),
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
                    widget.isEdit ? 'Salvar alteracoes' : 'Cadastrar cliente',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar cliente' : 'Cadastro de cliente'),
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

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = onlyNumbers(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _format(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String value) {
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      if (i == 3 || i == 6) {
        buffer.write('.');
      }

      if (i == 9) {
        buffer.write('-');
      }

      buffer.write(value[i]);
    }

    return buffer.toString();
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = onlyNumbers(newValue.text);
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final formatted = _format(limited);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _format(String value) {
    if (value.isEmpty) return value;

    if (value.length <= 2) {
      return '($value';
    }

    if (value.length <= 6) {
      return '(${value.substring(0, 2)}) ${value.substring(2)}';
    }

    if (value.length <= 10) {
      return '(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}';
    }

    return '(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7)}';
  }
}
