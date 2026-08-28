import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/service_offering_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServiceOfferingFormPage extends StatefulWidget {
  final String? serviceId;
  final String currentUserRole;

  const ServiceOfferingFormPage({
    super.key,
    this.serviceId,
    required this.currentUserRole,
  });

  bool get isEditing {
    return serviceId != null && serviceId!.isNotEmpty;
  }

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<ServiceOfferingFormPage> createState() =>
      _ServiceOfferingFormPageState();
}

class _ServiceOfferingFormPageState extends State<ServiceOfferingFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _serviceOfferingService = ServiceOfferingService(
    baseUrl: 'http://localhost:8081/service-offering',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _tokenStorage = TokenStorage();

  final _nameCtrl = TextEditingController();

  final _descriptionCtrl = TextEditingController();

  final _durationCtrl = TextEditingController();

  final _priceCtrl = TextEditingController();

  final _companyCtrl = TextEditingController();

  bool _loadingData = false;
  bool _saving = false;

  String _selectedStatus = 'ACTIVE';

  CompanyLookupOption? _selectedCompany;

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadService();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _durationCtrl.dispose();
    _priceCtrl.dispose();
    _companyCtrl.dispose();

    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadService() async {
    setState(() {
      _loadingData = true;
    });

    try {
      final token = await _getToken();

      final service = await _serviceOfferingService.findById(
        token: token,
        id: widget.serviceId!,
      );

      if (!mounted) return;

      setState(() {
        _nameCtrl.text = service.name;

        _descriptionCtrl.text = service.description;

        _durationCtrl.text = service.durationMinutes.toString();

        _priceCtrl.text = service.price.toStringAsFixed(2).replaceAll('.', ',');

        _selectedStatus = service.status.isNotEmpty ? service.status : 'ACTIVE';

        if (widget.isMasterAdmin && service.companyId.isNotEmpty) {
          _companyCtrl.text = service.companyId;
        }

        _loadingData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingData = false;
      });

      AppMessage.error(context, 'Erro ao carregar servico: $e');
    }
  }

  Future<void> _openCompanyZoom() async {
    if (widget.isEditing) {
      return;
    }

    final token = await _getToken();

    if (!mounted) return;

    final company = await CompanyLookupModal.show(
      context: context,
      token: token,
      service: _companyLookupService,
    );

    if (company == null) {
      return;
    }

    setState(() {
      _selectedCompany = company;
      _companyCtrl.text = company.displayName;
    });
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    if (widget.isMasterAdmin && !widget.isEditing && _selectedCompany == null) {
      AppMessage.info(context, 'Selecione uma empresa');

      return;
    }

    final duration = int.tryParse(_durationCtrl.text.trim());

    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));

    if (duration == null || duration <= 0) {
      AppMessage.error(context, 'Duracao invalida');

      return;
    }

    if (price == null || price < 0) {
      AppMessage.error(context, 'Preco invalido');

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _getToken();

      final request = ServiceOfferingRequest(
        name: _nameCtrl.text.trim(),

        description: _descriptionCtrl.text.trim(),

        durationMinutes: duration,

        price: price,

        status: _selectedStatus,

        companyId: widget.isMasterAdmin && !widget.isEditing
            ? _selectedCompany?.id
            : null,
      );

      if (widget.isEditing) {
        await _serviceOfferingService.updateService(
          token: token,
          id: widget.serviceId!,
          request: request,
        );
      } else {
        await _serviceOfferingService.createService(
          token: token,
          request: request,
        );
      }

      if (!mounted) return;

      AppMessage.success(
        context,
        widget.isEditing
            ? 'Servico atualizado com sucesso'
            : 'Servico cadastrado com sucesso',
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.error(context, 'Erro ao salvar servico: $e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
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

  Widget _buildCompanyField() {
    if (!widget.isMasterAdmin) {
      return const SizedBox.shrink();
    }

    return _buildTextField(
      controller: _companyCtrl,

      label: 'Empresa',

      hint: widget.isEditing ? 'Empresa vinculada' : 'Selecione a empresa',

      requiredField: !widget.isEditing,

      readOnly: true,

      onTap: widget.isEditing ? null : _openCompanyZoom,

      suffixIcon: widget.isEditing
          ? null
          : IconButton(
              onPressed: _openCompanyZoom,

              icon: const Icon(Icons.search),
            ),
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
            title: 'Dados do servico',

            children: [
              _buildResponsiveFields([
                if (widget.isMasterAdmin) _buildCompanyField(),

                _buildTextField(
                  controller: _nameCtrl,

                  label: 'Nome',

                  hint: 'Ex: Corte masculino',

                  requiredField: true,
                ),

                _buildTextField(
                  controller: _durationCtrl,

                  label: 'Duracao em minutos',

                  hint: 'Ex: 30',

                  requiredField: true,

                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                  customValidator: (value) {
                    final duration = int.tryParse(value);

                    if (duration == null || duration <= 0) {
                      return 'Duracao deve ser maior que zero';
                    }

                    return null;
                  },
                ),

                _buildTextField(
                  controller: _priceCtrl,

                  label: 'Preco',

                  hint: 'Ex: 50,00',

                  requiredField: true,

                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),

                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  ],

                  customValidator: (value) {
                    final price = double.tryParse(value.replaceAll(',', '.'));

                    if (price == null || price < 0) {
                      return 'Preco invalido';
                    }

                    return null;
                  },
                ),

                _buildStatusDropdown(),
              ]),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _descriptionCtrl,

                label: 'Descricao',

                hint: 'Descricao do servico',

                maxLines: 5,
              ),
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
                      widget.isEditing
                          ? 'Salvar alteracoes'
                          : 'Cadastrar servico',

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
    final title = widget.isEditing ? 'Editar servico' : 'Cadastrar servico';

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
