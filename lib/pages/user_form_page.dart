import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/services/user_admin_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';

class UserFormPage extends StatefulWidget {
  final String currentUserRole;

  const UserFormPage({
    super.key,
    required this.currentUserRole,
  });

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
    baseUrl: 'http://localhost:8081/user',
  );

  final _companyService = CompanyService(
    baseUrl: 'http://localhost:8081/company',
  );

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  String _selectedRole = 'CLIENT';

  CompanySummary? _selectedCompany;

  final List<String> _roleOptions = [
    'COMPANY_ADMIN',
    'CLIENT',
    'PROFESSIONAL',
  ];

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
    final company = await showDialog<CompanySummary>(
      context: context,
      builder: (_) {
        return CompanyZoomModal(
          companyService: _companyService,
        );
      },
    );

    if (company == null) return;

    setState(() {
      _selectedCompany = company;
      _companyCtrl.text = company.tradeName.isNotEmpty
          ? company.tradeName
          : company.legalName;
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
        companyId: widget.isMasterAdmin ? _selectedCompany?.id.toString() : null,
      );

      await _userAdminService.createUser(
        token: token,
        request: request,
      );

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
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.8),
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurface.withOpacity(0.45),
      ),
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
      decoration: _inputDecoration(
        label: 'Perfil',
      ),
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
                SizedBox(
                  width: width,
                  child: _buildRoleDropdown(),
                ),
                if (widget.isMasterAdmin)
                  SizedBox(
                    width: width,
                    child: _buildCompanyField(),
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
                    style: TextStyle(
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
        title: const Text('Cadastro de usuario'),
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

class CompanyZoomModal extends StatefulWidget {
  final CompanyService companyService;

  const CompanyZoomModal({
    super.key,
    required this.companyService,
  });

  @override
  State<CompanyZoomModal> createState() => _CompanyZoomModalState();
}

class _CompanyZoomModalState extends State<CompanyZoomModal> {
  final _searchCtrl = TextEditingController();

  List<CompanySummary> _companies = [];

  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  int _page = 0;
  final int _size = 10;
  bool _last = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _loading = true;
      _error = null;
      _page = 0;
      _last = true;
    });

    try {
      final page = await widget.companyService.findCompanies(
        page: 0,
        size: _size,
        type: null,
        search: _searchCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _companies = page.content;
        _page = page.number;
        _last = page.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreCompanies() async {
    if (_loadingMore || _last) return;

    setState(() {
      _loadingMore = true;
    });

    try {
      final page = await widget.companyService.findCompanies(
        page: _page + 1,
        size: _size,
        type: null,
        search: _searchCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _companies.addAll(page.content);
        _page = page.number;
        _last = page.last;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loadingMore = false;
      });
    }
  }

  InputDecoration _inputDecoration() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: 'Buscar empresa',
      filled: true,
      fillColor:
          isDark ? const Color(0xFF1C212B) : colorScheme.surfaceContainerHighest,
      prefixIcon: Icon(
        Icons.search,
        color: colorScheme.onSurface.withOpacity(0.65),
      ),
      suffixIcon: IconButton(
        onPressed: _loadCompanies,
        icon: const Icon(Icons.arrow_forward),
      ),
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
    );
  }

  Widget _buildCompanyRow(CompanySummary company) {
    final colorScheme = Theme.of(context).colorScheme;

    final displayName = company.tradeName.isNotEmpty
        ? company.tradeName
        : company.legalName;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(company);
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.12),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                company.typeLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesContent() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            'Erro ao buscar empresas',
            style: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    if (_companies.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: Text('Nenhuma empresa encontrada'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11141B) : colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF171A22)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Empresa',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tipo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ..._companies.map(_buildCompanyRow),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Pagina ${_page + 1}'),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _page == 0 ? null : () {},
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: _last ? null : _loadMoreCompanies,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF171A22) : null,
      title: const Text('Selecionar empresa'),
      content: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _loadCompanies(),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),
            _buildCompaniesContent(),
            const SizedBox(height: 12),
            _buildPagination(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}