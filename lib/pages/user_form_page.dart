import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:app_front_mobile/services/client_lookup_service.dart';
import 'package:app_front_mobile/widgets/client_lookup_modal.dart';
import 'package:app_front_mobile/services/professional_lookup_service.dart';
import 'package:app_front_mobile/widgets/professional_lookup_modal.dart';
import 'package:app_front_mobile/services/user_admin_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/theme/app_colors.dart';
import 'package:app_front_mobile/models/system_module.dart';
import 'package:app_front_mobile/utils/user_permissions.dart';
import 'package:app_front_mobile/widgets/app_scaffold.dart';

class UserFormPage extends StatefulWidget {
  final String currentUserRole;
  final String? userId;

  const UserFormPage({super.key, required this.currentUserRole, this.userId});

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  bool get isEditing {
    return userId != null && userId!.isNotEmpty;
  }

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenStorage = TokenStorage();

  final _userAdminService = UserAdminService(
    baseUrl: '${ApiConfig.baseUrl}/users',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: '${ApiConfig.baseUrl}/company/companies/home-page',
  );

  final _clientLookupService = ClientLookupService(
    baseUrl: '${ApiConfig.baseUrl}/client',
  );

  final _professionalLookupService = ProfessionalLookupService(
    baseUrl: '${ApiConfig.baseUrl}/professional',
  );

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _linkedClientCtrl = TextEditingController();
  final _linkedProfessionalCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingData = false;
  bool _obscurePassword = true;

  String _selectedRole = 'CLIENT';

  CompanyLookupOption? _selectedCompany;
  ClientLookupOption? _selectedClient;
  ProfessionalLookupOption? _selectedProfessional;
  bool _autoCreateLinkedRecord = false;

  final List<String> _roleOptions = ['COMPANY_ADMIN', 'CLIENT', 'PROFESSIONAL'];

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadUser();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _companyCtrl.dispose();
    _linkedClientCtrl.dispose();
    _linkedProfessionalCtrl.dispose();

    super.dispose();
  }

  Future<String> _getToken() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _loadUser() async {
    setState(() {
      _loadingData = true;
    });

    try {
      final token = await _getToken();

      final user = await _userAdminService.findById(
        token: token,
        id: widget.userId!,
      );

      if (!mounted) return;

      setState(() {
        _nameCtrl.text = user.name;
        _emailCtrl.text = user.email;
        _selectedRole = user.role;
        _loadingData = false;

        if (user.clientId.isNotEmpty) {
          _selectedClient = ClientLookupOption(
            id: user.clientId,
            name: user.clientName,
            cpfCnpj: '',
            companyId: '',
          );
          _linkedClientCtrl.text = user.clientName;
        }

        if (user.professionalId.isNotEmpty) {
          _selectedProfessional = ProfessionalLookupOption(
            id: user.professionalId,
            name: user.professionalName,
            cpfCnpj: '',
            companyId: '',
          );
          _linkedProfessionalCtrl.text = user.professionalName;
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingData = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar usuario');
    }
  }

  Future<void> _openCompanyZoom() async {
    final token = await _tokenStorage.getAccessToken();

    final company = await CompanyLookupModal.show(
      context: context,
      token: token,
      service: _companyLookupService,
    );

    if (company == null) return;

    setState(() {
      _selectedCompany = company;
      _companyCtrl.text = company.displayName;
    });
  }

  Future<void> _openClientZoom() async {
    final token = await _tokenStorage.getAccessToken();

    final client = await ClientLookupModal.show(
      context: context,
      token: token ?? '',
      service: _clientLookupService,
    );

    if (client == null) return;

    setState(() {
      _selectedClient = client;
      _linkedClientCtrl.text = client.name;
      _autoCreateLinkedRecord = false;
    });
  }

  void _clearClientLink() {
    setState(() {
      _selectedClient = null;
      _linkedClientCtrl.clear();
    });
  }

  Future<void> _openProfessionalZoom() async {
    final token = await _tokenStorage.getAccessToken();

    final professional = await ProfessionalLookupModal.show(
      context: context,
      token: token ?? '',
      service: _professionalLookupService,
    );

    if (professional == null) return;

    setState(() {
      _selectedProfessional = professional;
      _linkedProfessionalCtrl.text = professional.name;
      _autoCreateLinkedRecord = false;
    });
  }

  void _clearProfessionalLink() {
    setState(() {
      _selectedProfessional = null;
      _linkedProfessionalCtrl.clear();
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (!widget.isEditing && widget.isMasterAdmin && _selectedCompany == null) {
      _showMessage('Selecione uma empresa');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      if (widget.isEditing) {
        final request = UpdateUserRequest(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          role: _selectedRole,
          password: _passwordCtrl.text.trim().isEmpty
              ? null
              : _passwordCtrl.text.trim(),
          clientId: _selectedRole == 'CLIENT' ? _selectedClient?.id : null,
          professionalId: _selectedRole == 'PROFESSIONAL'
              ? _selectedProfessional?.id
              : null,
          autoCreateLinkedRecord: _autoCreateLinkedRecord,
        );

        await _userAdminService.update(
          token: token,
          id: widget.userId!,
          request: request,
        );
      } else {
        final request = CreateUserRequest(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          role: _selectedRole,
          companyId: widget.isMasterAdmin ? _selectedCompany?.id : null,
          clientId: _selectedRole == 'CLIENT' ? _selectedClient?.id : null,
          professionalId: _selectedRole == 'PROFESSIONAL'
              ? _selectedProfessional?.id
              : null,
          autoCreateLinkedRecord: _autoCreateLinkedRecord,
        );

        await _userAdminService.createUser(token: token, request: request);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar usuario.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
          ? AppColors.darkInputFill
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
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    VoidCallback? onTap,
    String? Function(String value)? customValidator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
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

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: _inputDecoration(label: 'Perfil'),
      items: _roleOptions.map((role) {
        return DropdownMenuItem<String>(
          value: role,
          child: Text(_formatRole(role)),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        setState(() {
          _selectedRole = value;

          if (_selectedRole != 'CLIENT') {
            _selectedClient = null;
            _linkedClientCtrl.clear();
          }

          if (_selectedRole != 'PROFESSIONAL') {
            _selectedProfessional = null;
            _linkedProfessionalCtrl.clear();
          }

          if (_selectedRole != 'CLIENT' && _selectedRole != 'PROFESSIONAL') {
            _autoCreateLinkedRecord = false;
          }
        });
      },
    );
  }

  String _formatRole(String role) {
    return switch (role) {
      'COMPANY_ADMIN' => 'Administrador da empresa',
      'CLIENT' => 'Cliente',
      'PROFESSIONAL' => 'Profissional',
      _ => role,
    };
  }

  Widget _buildCompanyField() {
    if (!widget.isMasterAdmin) {
      return const SizedBox.shrink();
    }

    return _buildTextField(
      controller: _companyCtrl,
      label: 'Empresa',
      hint: 'Selecione a empresa',
      requiredField: true,
      readOnly: true,
      onTap: _openCompanyZoom,
      suffixIcon: IconButton(
        onPressed: _openCompanyZoom,
        icon: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildLinkedEntityField() {
    if (_selectedRole == 'CLIENT') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _linkedClientCtrl,
            label: 'Cliente vinculado',
            hint: 'Selecione um cliente existente (opcional)',
            readOnly: true,
            onTap: _openClientZoom,
            suffixIcon: _selectedClient != null
                ? IconButton(
                    onPressed: _clearClientLink,
                    icon: const Icon(Icons.close),
                  )
                : IconButton(
                    onPressed: _openClientZoom,
                    icon: const Icon(Icons.search),
                  ),
          ),
          CheckboxListTile(
            value: _autoCreateLinkedRecord,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Cliente ainda nao existe - criar automaticamente',
            ),
            onChanged: _selectedClient != null
                ? null
                : (value) {
                    setState(() {
                      _autoCreateLinkedRecord = value ?? false;
                    });
                  },
          ),
        ],
      );
    }

    if (_selectedRole == 'PROFESSIONAL') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _linkedProfessionalCtrl,
            label: 'Profissional vinculado',
            hint: 'Selecione um profissional existente (opcional)',
            readOnly: true,
            onTap: _openProfessionalZoom,
            suffixIcon: _selectedProfessional != null
                ? IconButton(
                    onPressed: _clearProfessionalLink,
                    icon: const Icon(Icons.close),
                  )
                : IconButton(
                    onPressed: _openProfessionalZoom,
                    icon: const Icon(Icons.search),
                  ),
          ),
          CheckboxListTile(
            value: _autoCreateLinkedRecord,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Profissional ainda nao existe - criar automaticamente',
            ),
            onChanged: _selectedProfessional != null
                ? null
                : (value) {
                    setState(() {
                      _autoCreateLinkedRecord = value ?? false;
                    });
                  },
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _nameCtrl,
                    label: 'Nome',
                    requiredField: true,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    requiredField: true,
                    keyboardType: TextInputType.emailAddress,
                    customValidator: (value) {
                      if (!value.contains('@')) {
                        return 'Email invalido';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _buildTextField(
                    controller: _passwordCtrl,
                    label: widget.isEditing ? 'Nova senha (opcional)' : 'Senha',
                    requiredField: !widget.isEditing,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    customValidator: (value) {
                      if (value.isEmpty) {
                        return null;
                      }

                      if (value.length < 6) {
                        return 'Senha deve ter pelo menos 6 caracteres';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(width: width, child: _buildRoleDropdown()),
                if (!widget.isEditing && widget.isMasterAdmin)
                  SizedBox(width: width, child: _buildCompanyField()),
                SizedBox(
                  width: constraints.maxWidth,
                  child: _buildLinkedEntityField(),
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

    final canSubmit = widget.isEditing
        ? UserPermissions.can(SystemModule.user, CrudAction.update)
        : UserPermissions.can(SystemModule.user, CrudAction.create);

    if (_loadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isEditing ? 'Editar usuario' : 'Cadastro de usuario',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.isMasterAdmin
              ? 'Cadastre usuarios vinculando a uma empresa'
              : 'Cadastre usuarios vinculados a sua empresa',
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
            onPressed: _loading || !canSubmit ? null : _submit,
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
                    widget.isEditing ? 'Salvar alteracoes' : 'Cadastrar usuario',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
