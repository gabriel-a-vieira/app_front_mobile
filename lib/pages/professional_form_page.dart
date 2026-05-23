import 'package:app_front_mobile/services/professional_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/input_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_front_mobile/services/state_service.dart';

class ProfessionalFormPage extends StatefulWidget {
  final String? professionalId;

  const ProfessionalFormPage({super.key, this.professionalId});

  bool get isEditing {
    return professionalId != null && professionalId!.isNotEmpty;
  }

  @override
  State<ProfessionalFormPage> createState() => _ProfessionalFormPageState();
}

class _ProfessionalFormPageState extends State<ProfessionalFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _professionalService = ProfessionalService(
    baseUrl: 'http://localhost:8081/professional',
  );

  final _stateService = StateService(baseUrl: 'http://localhost:8081/state');
  final _tokenStorage = TokenStorage();

  final _nameCtrl = TextEditingController();
  final _cpfCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  final _postalCodeCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  bool _loadingStates = true;

  StateOption? _selectedState;
  List<StateOption> _states = [];

  String _selectedGender = 'MASCULINO';
  String _selectedStatus = 'ACTIVE';

  final List<String> _genderOptions = ['MASCULINO', 'FEMININO', 'OUTRO'];

  final List<String> _statusOptions = ['ACTIVE', 'INACTIVE'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cpfCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();

    _postalCodeCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _cityCtrl.dispose();
    _complementCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingStates = true;
      _loadingData = widget.isEditing;
    });

    try {
      final states = await _stateService.findStates();

      ProfessionalSummary? professional;

      if (widget.isEditing) {
        final token = await _getToken();

        professional = await _professionalService.findById(
          token: token,
          id: widget.professionalId!,
        );
      }

      if (!mounted) return;

      setState(() {
        _states = states;
        _loadingStates = false;

        if (professional != null) {
          _fillForm(professional);
        }

        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStates = false;
        _loadingData = false;
      });

      _showMessage('Erro ao carregar dados: $e');
    }
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  void _fillForm(ProfessionalSummary professional) {
    _nameCtrl.text = professional.name;
    _cpfCtrl.text = _formatCpf(professional.cpfCnpj);
    _phoneCtrl.text = _formatPhone(professional.phone);
    _birthDateCtrl.text = _formatDateFromApi(professional.birthDate);

    _postalCodeCtrl.text = _formatCep(professional.postalCode);
    _streetCtrl.text = professional.street;
    _numberCtrl.text = professional.number;
    _neighborhoodCtrl.text = professional.neighborhood;
    _cityCtrl.text = professional.city;
    _complementCtrl.text = professional.complement;

    _selectedGender = professional.gender.isNotEmpty
        ? professional.gender
        : _selectedGender;

    _selectedStatus = professional.status.isNotEmpty
        ? professional.status
        : _selectedStatus;

    final professionalState = professional.state.trim().toUpperCase();

    if (professionalState.isNotEmpty) {
      _selectedState = _states.firstWhere(
        (state) => state.abbreviation.toUpperCase() == professionalState,
        orElse: () => StateOption(
          id: '',
          name: professionalState,
          abbreviation: professionalState,
        ),
      );
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      final request = ProfessionalRequest(
        name: _nameCtrl.text.trim(),
        cpfCnpj: onlyNumbers(_cpfCtrl.text),
        phone: onlyNumbers(_phoneCtrl.text),
        birthDate: _birthDateCtrl.text.trim(),
        gender: _selectedGender,
        status: _selectedStatus,
        street: _streetCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        postalCode: onlyNumbers(_postalCodeCtrl.text),
        complement: _complementCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _selectedState?.abbreviation ?? '',
      );

      if (widget.isEditing) {
        await _professionalService.updateProfessional(
          token: token,
          id: widget.professionalId!,
          request: request,
        );
      } else {
        await _professionalService.createProfessional(
          token: token,
          request: request,
        );
      }

      if (!mounted) return;

      _showMessage(
        widget.isEditing
            ? 'Profissional atualizado com sucesso'
            : 'Profissional cadastrado com sucesso',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao salvar profissional: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _parseDate(_birthDateCtrl.text) ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selectedDate == null) return;

    _birthDateCtrl.text = _formatDate(selectedDate);
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final parts = value.split('-');

      if (parts.length != 3) return null;

      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatDateFromApi(String value) {
    if (value.isEmpty) return '';

    if (value.length >= 10) {
      return value.substring(0, 10);
    }

    return value;
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      onChanged: _loadingStates
          ? null
          : (value) {
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool requiredField = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String value)? customValidator,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> options,
    required void Function(String? value) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label: label),
      items: options.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(_formatOptionLabel(option)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String _formatOptionLabel(String value) {
    return switch (value) {
      'ACTIVE' => 'Ativo',
      'INACTIVE' => 'Inativo',
      'MASCULINO' => 'Masculino',
      'FEMININO' => 'Feminino',
      'OUTRO' => 'Outro',
      _ => value,
    };
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

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

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
        children: [
          _buildFormCard(
            title: 'Dados pessoais',
            children: [
              _buildResponsiveFields([
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Nome',
                  requiredField: true,
                ),
                _buildTextField(
                  controller: _cpfCtrl,
                  label: 'CPF',
                  hint: '000.000.000-00',
                  requiredField: true,
                  inputFormatters: [_CpfInputFormatter()],
                  customValidator: (value) {
                    final digits = onlyNumbers(value);

                    if (digits.length != 11) {
                      return 'CPF deve ter 11 digitos';
                    }

                    return null;
                  },
                ),
                _buildTextField(
                  controller: _phoneCtrl,
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
                _buildTextField(
                  controller: _birthDateCtrl,
                  label: 'Data de nascimento',
                  hint: 'AAAA-MM-DD',
                  readOnly: true,
                  onTap: _selectBirthDate,
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                _buildDropdown(
                  label: 'Genero',
                  value: _selectedGender,
                  options: _genderOptions,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedGender = value;
                    });
                  },
                ),
                _buildDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  options: _statusOptions,
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
              ]),
            ],
          ),
          const SizedBox(height: 18),
          _buildFormCard(
            title: 'Endereco',
            children: [
              _buildResponsiveFields([
                _buildTextField(
                  controller: _postalCodeCtrl,
                  label: 'CEP',
                  hint: '00000-000',
                  inputFormatters: [CepInputFormatter()],
                  customValidator: (value) {
                    final digits = onlyNumbers(value);

                    if (digits.isNotEmpty && digits.length != 8) {
                      return 'CEP deve ter 8 digitos';
                    }

                    return null;
                  },
                ),
                _buildTextField(controller: _streetCtrl, label: 'Rua'),
                _buildTextField(controller: _numberCtrl, label: 'Numero'),
                _buildTextField(controller: _neighborhoodCtrl, label: 'Bairro'),
                _buildTextField(
                  controller: _cityCtrl,
                  label: 'Cidade',
                  requiredField: true,
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
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
                          : 'Cadastrar profissional',
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
    final title = widget.isEditing
        ? 'Editar profissional'
        : 'Cadastrar profissional';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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

class _UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final upperText = newValue.text.toUpperCase();

    return TextEditingValue(
      text: upperText,
      selection: TextSelection.collapsed(offset: upperText.length),
    );
  }
}
