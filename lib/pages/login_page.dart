import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  final VoidCallback? onRegisterTap;

  const LoginPage({
    super.key,
    this.onLoginSuccess,
    this.onRegisterTap,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  final _authService = AuthService(baseUrl: 'http://localhost:8081');
  final _tokenStorage = TokenStorage();

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
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _loading = true);

    try {
      final token = await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      await _tokenStorage.saveAccessToken(token);

      if (!mounted) return;

      widget.onLoginSuccess?.call();
    } catch (e, stackTrace) {
      debugPrint('Erro durante o login: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.loginError}: $e'),
        ),
      );
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
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 575),
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
                      _buildBody(),
                      _buildFooter(),
                    ],
                  ),
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
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      child: Row(
        children: [
          const Spacer(),
          Text(
            l10n.accessAccount,
            style: const TextStyle(
              color: _whiteText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _close,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3F4A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF4A505C), width: 1),
              ),
              child: const Icon(Icons.close, color: _whiteText, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Column(
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

          const SizedBox(height: 18),

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

          _FieldLabel(title: l10n.email, requiredField: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: const TextStyle(
              color: _whiteText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            decoration: _inputDecoration(
              hintText: l10n.emailHint,
              prefixIcon: Icons.person_outline,
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
            autofillHints: const [AutofillHints.password],
            style: const TextStyle(
              color: _whiteText,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
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

              return null;
            },
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {},
              child: Text(
                l10n.forgotPassword,
                style: const TextStyle(
                  color: Color(0xFFD0D6E1),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFFD0D6E1),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primaryBlue,
                disabledBackgroundColor: const Color(0xFF4D84B0),
                foregroundColor: _whiteText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(_whiteText),
                      ),
                    )
                  : Text(l10n.access),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
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
                l10n.dontHaveAccount,
                style: const TextStyle(
                  color: _whiteText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: widget.onRegisterTap,
                child: Text(
                  l10n.signUp,
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
              InkWell(
                onTap: () {},
                child: Text(
                  l10n.termsOfUse,
                  style: const TextStyle(
                    color: Color(0xFFBFC7D3),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFFBFC7D3),
                  ),
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