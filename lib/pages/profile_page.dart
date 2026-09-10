import 'package:app_front_mobile/services/profile_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _profileService = ProfileService(baseUrl: 'http://localhost:8081');

  final _tokenStorage = TokenStorage();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _cpfController = TextEditingController();

  final _phoneController = TextEditingController();

  final _birthDateController = TextEditingController();

  MyProfile? _profile;

  DateTime? _birthDate;

  String? _gender;

  bool _loading = true;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _cpfController.dispose();

    _phoneController.dispose();

    _birthDateController.dispose();

    super.dispose();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Token não encontrado.');
    }

    return token;
  }

  Future<void> _loadProfile() async {
    try {
      final token = await _token();

      final profile = await _profileService.findMyProfile(token: token);

      if (!mounted) {
        return;
      }

      _applyProfile(profile);

      setState(() {
        _profile = profile;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar seu perfil.');
    }
  }

  void _applyProfile(MyProfile profile) {
    _nameController.text = profile.name;

    _emailController.text = profile.email;

    _cpfController.text = _formatCpf(profile.cpfCnpj ?? '');

    _phoneController.text = _formatPhone(profile.phone ?? '');

    _birthDate = profile.birthDate;

    _birthDateController.text = _formatDate(profile.birthDate);

    _gender = profile.gender;
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900, 1, 1),
      lastDate: now,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _birthDate = selected;

      _birthDateController.text = _formatDate(selected);
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _token();

      final request = UpdateMyProfileRequest(
        name: _nameController.text.trim(),

        cpfCnpj: _onlyNumbers(_cpfController.text),

        phone: _onlyNumbers(_phoneController.text),

        birthDate: _birthDate,

        gender: _gender,
      );

      final profile = await _profileService.updateMyProfile(
        token: token,
        request: request,
      );

      if (!mounted) {
        return;
      }

      _applyProfile(profile);

      setState(() {
        _profile = profile;
      });

      AppMessage.success(context, 'Perfil atualizado com sucesso.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      AppMessage.apiError(
        context,
        e,
        fallback: 'Erro ao atualizar seu perfil.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _onlyNumbers(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  String _formatCpf(String value) {
    final numbers = _onlyNumbers(value);

    if (numbers.length != 11) {
      return value;
    }

    return '${numbers.substring(0, 3)}.'
        '${numbers.substring(3, 6)}.'
        '${numbers.substring(6, 9)}-'
        '${numbers.substring(9, 11)}';
  }

  String _formatPhone(String value) {
    final numbers = _onlyNumbers(value);

    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) '
          '${numbers.substring(2, 7)}-'
          '${numbers.substring(7, 11)}';
    }

    if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) '
          '${numbers.substring(2, 6)}-'
          '${numbers.substring(6, 10)}';
    }

    return value;
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');

    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year}';
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'MASTER_ADMIN':
        return 'Administrador Master';

      case 'COMPANY_ADMIN':
        return 'Administrador da empresa';

      case 'PROFESSIONAL':
        return 'Profissional';

      case 'CLIENT':
        return 'Cliente';

      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  const SizedBox(height: 24),

                  if (_profile != null && !_profile!.personalDataCompleted)
                    _buildIncompleteBanner(),

                  if (_profile != null && !_profile!.personalDataCompleted)
                    const SizedBox(height: 18),

                  _buildAccountCard(),

                  const SizedBox(height: 18),

                  _buildPersonalCard(),

                  const SizedBox(height: 18),

                  _buildConnectedAccountsCard(),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 180,
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar'),
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

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meu perfil',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Gerencie as informações da sua conta e seus dados pessoais.',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.62),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildIncompleteBanner() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.primary.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Complete seus dados pessoais para facilitar seus próximos agendamentos.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return _buildCard(
      title: 'Informações da conta',
      icon: Icons.account_circle_outlined,
      child: Column(
        children: [
          _buildResponsiveFields([
            TextFormField(
              controller: _nameController,
              decoration: _decoration('Nome', Icons.person_outline),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome obrigatório';
                }

                return null;
              },
            ),

            TextFormField(
              controller: _emailController,
              enabled: false,
              decoration: _decoration(
                'E-mail',
                Icons.mail_outline,
              ).copyWith(suffixIcon: const Icon(Icons.lock_outline)),
            ),
          ]),

          const SizedBox(height: 14),

          _buildReadOnlyInfo(
            label: 'Tipo da conta',
            value: _roleLabel(_profile?.role ?? ''),
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalCard() {
    return _buildCard(
      title: 'Informações pessoais',
      icon: Icons.assignment_ind_outlined,
      child: Column(
        children: [
          _buildResponsiveFields([
            TextFormField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: _decoration('CPF', Icons.credit_card_outlined),
              validator: (value) {
                final numbers = _onlyNumbers(value ?? '');

                if (numbers.isNotEmpty && numbers.length != 11) {
                  return 'CPF deve possuir 11 dígitos';
                }

                return null;
              },
            ),

            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: _decoration('Telefone', Icons.phone_outlined),
            ),

            TextFormField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _selectBirthDate,
              decoration: _decoration(
                'Data de nascimento',
                Icons.calendar_month_outlined,
              ).copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined)),
            ),

            DropdownButtonFormField<String>(
              value: _gender,
              decoration: _decoration('Gênero', Icons.person_outline),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Masculino')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Feminino')),
                DropdownMenuItem(value: 'OTHER', child: Text('Outro')),
                DropdownMenuItem(
                  value: 'NOT_INFORMED',
                  child: Text('Prefiro não informar'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _gender = value;
                });
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildConnectedAccountsCard() {
    final googleLinked = _profile?.googleLinked ?? false;

    return _buildCard(
      title: 'Contas conectadas',
      icon: Icons.security_outlined,
      child: Column(
        children: [
          _buildProviderRow(name: 'Google', linked: googleLinked),

          const Divider(height: 28),

          _buildProviderRow(name: 'Facebook', linked: false, comingSoon: true),

          const Divider(height: 28),

          _buildProviderRow(name: 'Apple', linked: false, comingSoon: true),
        ],
      ),
    );
  }

  Widget _buildProviderRow({
    required String name,
    required bool linked,
    bool comingSoon = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(
            name == 'Google'
                ? Icons.g_mobiledata
                : name == 'Facebook'
                ? Icons.facebook
                : Icons.apple,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        if (comingSoon)
          Text(
            'Em breve',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.55)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: linked
                  ? const Color(0xFF2EAD72).withOpacity(0.12)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              linked ? 'Vinculada' : 'Não vinculada',
              style: TextStyle(
                color: linked
                    ? const Color(0xFF2EAD72)
                    : colorScheme.onSurface.withOpacity(0.65),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15171D) : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: colorScheme.primary),

              const SizedBox(width: 9),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          child,
        ],
      ),
    );
  }

  Widget _buildResponsiveFields(List<Widget> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 700;

        final width = twoColumns
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: fields
              .map((field) => SizedBox(width: width, child: field))
              .toList(),
        );
      },
    );
  }

  Widget _buildReadOnlyInfo({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return InputDecorator(
      decoration: _decoration(label, icon),
      child: Text(value.isEmpty ? '-' : value),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.35),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.22)),
      ),
    );
  }
}
