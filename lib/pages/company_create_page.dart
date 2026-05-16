import 'package:app_front_mobile/services/company_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:flutter/material.dart';

class CompanyCreatePage extends StatefulWidget {
  const CompanyCreatePage({super.key});

  @override
  State<CompanyCreatePage> createState() => _CompanyCreatePageState();
}

class _CompanyCreatePageState extends State<CompanyCreatePage> {
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
  final _stateCtrl = TextEditingController();
  final _complementCtrl = TextEditingController();

  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  final _companyService = CompanyService(baseUrl: 'http://localhost:8081');
  final _tokenStorage = TokenStorage();

  bool _loading = false;
  bool _loadingTypes = true;

  String? _selectedType;
  List<CompanyTypeOption> _types = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
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
    _stateCtrl.dispose();
    _complementCtrl.dispose();

    _instagramCtrl.dispose();
    _facebookCtrl.dispose();
    _websiteCtrl.dispose();
    _tiktokCtrl.dispose();

    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _companyService.findCompanyTypes();

      if (!mounted) return;

      setState(() {
        _types = types;
        _loadingTypes = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingTypes = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar tipos de empresa: $e')),
      );
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() => _loading = true);

    try {
      final token = await _tokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token nao encontrado');
      }

      final request = CreateCompanyRequest(
        legalName: _legalNameCtrl.text.trim(),
        tradeName: _tradeNameCtrl.text.trim(),
        cnpj: _cnpjCtrl.text.trim(),
        type: _selectedType ?? '',
        imageUrl: _imageUrlCtrl.text.trim(),
        zipCode: _zipCodeCtrl.text.trim(),
        street: _streetCtrl.text.trim(),
        number: _numberCtrl.text.trim(),
        district: _districtCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim().toUpperCase(),
        complement: _complementCtrl.text.trim(),
        instagramUrl: _instagramCtrl.text.trim(),
        facebookUrl: _facebookCtrl.text.trim(),
        websiteUrl: _websiteCtrl.text.trim(),
        tiktokUrl: _tiktokCtrl.text.trim(),
      );

      await _companyService.createCompany(
        token: token,
        request: request,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa cadastrada com sucesso')),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cadastrar empresa: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: isDark
          ? const Color(0xFF1C212B)
          : colorScheme.surfaceContainerHighest,
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
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
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
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          ...children,
        ],
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
            return SizedBox(
              width: width,
              child: field,
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Empresa'),
      ),
      body: SingleChildScrollView(
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
                          requiredField: true,
                          keyboardType: TextInputType.number,
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: _inputDecoration(label: 'Tipo'),
                          items: _types.map((type) {
                            return DropdownMenuItem<String>(
                              value: type.code,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: _loadingTypes
                              ? null
                              : (value) {
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
                        ),
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
                        _buildTextField(
                          controller: _stateCtrl,
                          label: 'UF',
                          hint: 'SC',
                        ),
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
                              'Cadastrar empresa',
                              style: TextStyle(
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