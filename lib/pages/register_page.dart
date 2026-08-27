import 'package:app_front_mobile/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback? onLoginTap;
  final VoidCallback? onRegisterSuccess;

  const RegisterPage({super.key, this.onLoginTap, this.onRegisterSuccess});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _authService = AuthService(baseUrl: 'http://localhost:8081');

  bool _loading = false;
  bool _obscure = true;
  bool _showScrollbar = false;

  static const Color _modalColor = Color(0xFF11141B);
  static const Color _headerColor = Color(0xFF1A1E26);
  static const Color _borderColor = Color(0xFF2A2F38);
  static const Color _inputFillColor = Color(0xFF1C212B);
  static const Color _socialButtonColor = Color(0xFF090B10);
  static const Color _primaryBlue = Color(0xFF0089F7);
  static const Color _whiteText = Color(0xFFF5F7FA);
  static const Color _mutedText = Color(0xFF9EA6B2);
  static const Color _hintText = Color(0xFF8D95A3);
  static const Color _linkBlue = Color(0xFF36A9FF);
  static const Color _dangerRed = Color(0xFFFF5A5F);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (_scrollController.hasClients) {
        setState(() {
          _showScrollbar = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    debugPrint('Botao Cadastrar clicado');

    final isValid = _formKey.currentState?.validate() ?? false;

    debugPrint('Formulario valido? $isValid');

    if (!isValid) {
      debugPrint('Cadastro bloqueado pela validacao do formulario');
      return;
    }

    setState(() => _loading = true);

    try {
      debugPrint('Chamando AuthService.register');

      await _authService.register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      debugPrint('Cadastro realizado com sucesso');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.registerSuccess)));

      widget.onRegisterSuccess?.call();
    } catch (e, stackTrace) {
      debugPrint('Erro durante o cadastro: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${l10n.registerError}: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: _hintText,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: _inputFillColor,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      prefixIcon: Icon(prefixIcon, color: _mutedText, size: 20),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _whiteText, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _dangerRed, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _dangerRed, width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _borderColor, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 575,
            maxHeight: screenHeight * 0.92,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: _modalColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(
                      child: RawScrollbar(
                        controller: _scrollController,
                        thumbVisibility: _showScrollbar,
                        trackVisibility: _showScrollbar,
                        thickness: 8,
                        radius: const Radius.circular(999),
                        thumbColor: const Color(0xFF7B7F88),
                        trackColor: const Color(0xFF242832),
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          primary: false,
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                          child: _buildBody(),
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(
            child: Center(
              child: Text(
                l10n.registerTitle,
                style: const TextStyle(
                  color: _whiteText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: _close,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F4A),
                shape: BoxShape.circle,
                border: Border.all(color: _primaryBlue, width: 1.5),
              ),
              child: const Icon(Icons.close, color: _whiteText, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.continueWith,
          style: const TextStyle(
            color: _whiteText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                text: 'Google',
                icon: const FaIcon(
                  FontAwesomeIcons.google,
                  size: 16,
                  color: Color.fromARGB(255, 244, 72, 66),
                ),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                text: 'Facebook',
                icon: const FaIcon(
                  FontAwesomeIcons.facebookF,
                  size: 16,
                  color: Color(0xFF1877F2),
                ),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SocialButton(
                text: 'Apple',
                icon: const FaIcon(
                  FontAwesomeIcons.apple,
                  size: 18,
                  color: _whiteText,
                ),
                onTap: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider(color: _borderColor, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.or,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const Expanded(child: Divider(color: _borderColor, thickness: 1)),
          ],
        ),
        const SizedBox(height: 18),
        _FieldLabel(title: l10n.fullName, requiredField: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameCtrl,
          style: const TextStyle(color: _whiteText, fontSize: 15),
          decoration: _inputDecoration(
            hintText: l10n.fullNameHint,
            prefixIcon: Icons.person_outline,
          ),
          validator: (v) {
            final value = (v ?? '').trim();

            if (value.isEmpty) {
              return l10n.requiredFullName;
            }

            if (value.length < 3) {
              return l10n.invalidFullName;
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        _FieldLabel(title: l10n.email, requiredField: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: _whiteText, fontSize: 15),
          decoration: _inputDecoration(
            hintText: l10n.emailHint,
            prefixIcon: Icons.mail_outline,
          ),
          validator: (v) {
            final value = (v ?? '').trim();

            if (value.isEmpty) {
              return l10n.requiredEmail;
            }

            if (!value.contains('@')) {
              return l10n.invalidEmail;
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        _FieldLabel(title: l10n.password, requiredField: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscure,
          style: const TextStyle(color: _whiteText, fontSize: 15),
          decoration: _inputDecoration(
            hintText: l10n.passwordHint,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              splashRadius: 18,
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _mutedText,
                size: 22,
              ),
            ),
          ),
          validator: (v) {
            final value = v ?? '';

            if (value.isEmpty) {
              return l10n.requiredPassword;
            }

            if (value.length < 4) {
              return l10n.minimumPassword;
            }

            return null;
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: FilledButton(
            onPressed: _loading ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _primaryBlue,
              foregroundColor: _whiteText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_whiteText),
                    ),
                  )
                : Text(l10n.registerButton),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                l10n.alreadyHaveAccount,
                style: const TextStyle(
                  color: _whiteText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: widget.onLoginTap,
                child: Text(
                  l10n.goToLogin,
                  style: const TextStyle(
                    color: _linkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Text(
                l10n.termsPrefix,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                l10n.termsOfUse,
                style: const TextStyle(
                  color: Color(0xFFBFC7D3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFBFC7D3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String title;
  final bool requiredField;

  const _FieldLabel({required this.title, this.requiredField = false});

  static const Color _whiteText = Color(0xFFF5F7FA);
  static const Color _dangerRed = Color(0xFFFF5A5F);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _whiteText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (requiredField) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: _dangerRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  static const Color _socialButtonColor = Color(0xFF090B10);
  static const Color _borderColor = Color(0xFF2A2F38);
  static const Color _whiteText = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: _socialButtonColor,
          foregroundColor: _whiteText,
          side: const BorderSide(color: _borderColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _whiteText,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
