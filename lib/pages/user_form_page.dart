import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:app_front_mobile/services/user_admin_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  final String currentUserRole;

  const UserFormPage({super.key, required this.currentUserRole});

  bool get isMasterAdmin {
    return currentUserRole.toUpperCase() == 'MASTER_ADMIN';
  }

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _tokenStorage = TokenStorage();

  final _userAdminService = UserAdminService(
    baseUrl: 'http://localhost:8081/auth/register',
  );

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company/companies/home-page',
  );

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  String _selectedRole = 'CLIENT';

  CompanyLookupOption? _selectedCompany;

  final List<String> _roleOptions = ['COMPANY_ADMIN', 'CLIENT', 'PROFESSIONAL'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (widget.isMasterAdmin && _selectedCompany == null) {
      _showMessage('Selecione uma empresa');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final token = await _getToken();

      final request = CreateUserRequest(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: _selectedRole,
        companyId: widget.isMasterAdmin ? _selectedCompany?.id : null,
      );

      await _userAdminService.createUser(token: token, request: request);

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Erro ao cadastrar usuario: $e');
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

  Widget _buildFormCard() {
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
                    label: 'Senha',
                    requiredField: true,
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
                      if (value.length < 6) {
                        return 'Senha deve ter pelo menos 6 caracteres';
                      }

                      return null;
                    },
                  ),
                ),
                SizedBox(width: width, child: _buildRoleDropdown()),
                if (widget.isMasterAdmin)
                  SizedBox(width: width, child: _buildCompanyField()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cadastro de usuario',
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
                : const Text(
                    'Cadastrar usuario',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de usuario')),
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