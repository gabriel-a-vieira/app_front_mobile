import 'package:app_front_mobile/services/city_service.dart';
import 'package:app_front_mobile/services/client_service.dart';
import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/services/state_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:app_front_mobile/widgets/company_zoom_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  final _clientService = ClientService(
    baseUrl: 'http://localhost:8081/client',
  );

  final _stateService = StateService(
    baseUrl: 'http://localhost:8081/state',
  );

  final _cityService = CityService(
    baseUrl: 'http://localhost:8081/city',
  );

  final _companyService = CompanyService(
    baseUrl: 'http://localhost:8081/company',
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

  bool _loading = true;
  bool _saving = false;

  DateTime? _selectedBirthDate;

  String _selectedGender = 'MASCULINO';
  String _selectedStatus = 'ACTIVE';
  String _selectedPaymentMethod = '';

  List<String> _paymentMethods = [];
  List<StateOption> _states = [];
  List<CityOption> _cities = [];

  StateOption? _selectedState;
  CityOption? _selectedCity;
  CompanySummary? _selectedCompany;

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

      _showMessage('Erro ao carregar dados: $e');
    }
  }

  Future<void> _loadClient(String token) async {
    final client = await _clientService.findById(
      token: token,
      id: widget.clientId!,
    );

    _nameController.text = client.name;
    _cpfCnpjController.text = client.cpfCnpj;
    _phoneController.text = client.phone;
    _streetController.text = client.street;
    _numberController.text = client.number;
    _postalCodeController.text = client.postalCode;
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

    if (client.state.isNotEmpty) {
      final state = _findStateByAbbreviation(client.state);

      if (state != null) {
        _selectedState = state;
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

  CityOption? _findCityById(String id) {
    for (final city in _cities) {
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
    final cities = await _cityService.findByState(
      state: state,
    );

    if (!mounted) return;

    setState(() {
      _cities = cities;
      _selectedCity = selectedCityId != null && selectedCityId.isNotEmpty
          ? _findCityById(selectedCityId)
          : null;
    });
  }

  Future<void> _openCompanyZoom() async {
    if (widget.isEdit) {
      return;
    }

    final company = await CompanyZoomModal.show(
      context: context,
      companyService: _companyService,
    );

    if (company == null) return;

    setState(() {
      _selectedCompany = company;
      _companyController.text = _companyDisplayName(company);
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
      _showMessage('Selecione a cidade');
      return;
    }

    if (widget.isMasterAdmin && !widget.isEdit && _selectedCompany == null) {
      _showMessage('Selecione a empresa');
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
            ? _selectedCompany?.id
            : null,
        cityId: _selectedCity?.id ?? '',
        city: _selectedCity?.name ?? '',
        state: _selectedState?.abbreviation ?? '',
        street: _streetController.text.trim(),
        number: _numberController.text.trim(),
        postalCode: onlyNumbers(_postalCodeController.text),
        complement: _complementController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
      );

      if (widget.isEdit) {
        await _clientService.updateClient(
          token: token,
          id: widget.clientId!,
          request: request,
        );
      } else {
        await _clientService.createClient(
          token: token,
          request: request,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao salvar cliente: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _companyDisplayName(CompanySummary company) {
    if (company.tradeName.isNotEmpty) {
      return company.tradeName;
    }

    if (company.legalName.isNotEmpty) {
      return company.legalName;
    }

    return 'Empresa sem nome';
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
      fillColor:
          isDark ? const Color(0xFF1C212B) : colorScheme.surfaceContainerHighest,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.outline.withOpacity(0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.primary,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: colorScheme.error,
        ),
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

        return null;
      },
    );
  }

  Widget _buildStateDropdown() {
    return DropdownButtonFormField<StateOption>(
      value: _selectedState,
      decoration: _inputDecoration(
        label: 'UF',
      ),
      items: _states.map((state) {
        return DropdownMenuItem<StateOption>(
          value: state,
          child: Text(state.label),
        );
      }).toList(),
      onChanged: (state) async {
        if (state == null) return;

        setState(() {
          _selectedState = state;
          _selectedCity = null;
          _cities = [];
        });

        await _loadCitiesByState(state.abbreviation);
      },
      validator: (value) {
        if (value == null) {
          return 'UF e obrigatorio';
        }

        return null;
      },
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<CityOption>(
      value: _selectedCity,
      decoration: _inputDecoration(
        label: 'Cidade',
      ),
      items: _cities.map((city) {
        return DropdownMenuItem<CityOption>(
          value: city,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: (city) {
        setState(() {
          _selectedCity = city;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Cidade e obrigatoria';
        }

        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: _inputDecoration(
        label: 'Genero',
      ),
      items: const [
        DropdownMenuItem(
          value: 'MASCULINO',
          child: Text('Masculino'),
        ),
        DropdownMenuItem(
          value: 'FEMININO',
          child: Text('Feminino'),
        ),
        DropdownMenuItem(
          value: 'OUTRO',
          child: Text('Outro'),
        ),
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
      decoration: _inputDecoration(
        label: 'Status',
      ),
      items: const [
        DropdownMenuItem(
          value: 'ACTIVE',
          child: Text('Ativo'),
        ),
        DropdownMenuItem(
          value: 'INACTIVE',
          child: Text('Inativo'),
        ),
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
      decoration: _inputDecoration(
        label: 'Forma de pagamento preferida',
      ),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Nao informado'),
        ),
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

  Widget _buildFormCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;
            final width =
                isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                if (widget.isMasterAdmin)
                  SizedBox(
                    width: width,
                    child: _buildCompanyField(),
                  ),
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
                    label: 'CPF/CNPJ',
                    requiredField: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _phoneController,
                    label: 'Telefone',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
                SizedBox(
                  width: width,
                  child: _buildGenderDropdown(),
                ),
                SizedBox(
                  width: width,
                  child: _buildPaymentDropdown(),
                ),
                SizedBox(
                  width: width,
                  child: _buildStatusDropdown(),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _postalCodeController,
                    label: 'CEP',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
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
                SizedBox(
                  width: width,
                  child: _buildStateDropdown(),
                ),
                SizedBox(
                  width: width,
                  child: _buildCityDropdown(),
                ),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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
            constraints: const BoxConstraints(
              maxWidth: 980,
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
}