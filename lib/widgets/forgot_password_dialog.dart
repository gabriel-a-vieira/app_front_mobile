import 'dart:async';

import 'package:app_front_mobile/config/api_config.dart';
import 'package:app_front_mobile/l10n/app_localizations.dart';
import 'package:app_front_mobile/services/auth_service.dart';
import 'package:app_front_mobile/theme/auth_dialog_colors.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// "Recuperar senha" modal, opened from the login modal. Two steps:
///
/// 1. e-mail -> backend e-mails a 6-digit code;
/// 2. code + new password -> backend checks the code and saves the password.
///
/// Pops with the e-mail used when the password was changed (so the login
/// modal can prefill it), or null when closed without finishing.
class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final AuthService? authService;

  const ForgotPasswordDialog({
    super.key,
    this.initialEmail = '',
    this.authService,
  });

  static Future<String?> show(
    BuildContext context, {
    String initialEmail = '',
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ForgotPasswordDialog(initialEmail: initialEmail),
      ),
    );
  }

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  /// Same value as the backend's PasswordResetService.RESEND_COOLDOWN_SECONDS:
  /// a resend before that is silently ignored there, so don't offer it here.
  static const int _resendCooldownSeconds = 60;

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailCtrl;
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  late final AuthService _authService;

  bool _codeSent = false;
  bool _loading = false;
  bool _obscure = true;
  int _resendIn = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail.trim());
    _authService =
        widget.authService ?? AuthService(baseUrl: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _email => _emailCtrl.text.trim();

  Future<void> _sendCode({bool isResend = false}) async {
    final l10n = AppLocalizations.of(context);

    if (!isResend && !(_emailFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _loading = true);

    try {
      await _authService.requestPasswordReset(email: _email);

      if (!mounted) return;

      setState(() => _codeSent = true);
      _startResendCooldown();

      if (isResend) {
        AppMessage.info(context, l10n.forgotPasswordCodeSent);
      }
    } catch (e) {
      if (!mounted) return;
      AppMessage.apiError(
        context,
        e,
        fallback: l10n.forgotPasswordRequestError,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);

    if (!(_resetFormKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await _authService.confirmPasswordReset(
        email: _email,
        code: _codeCtrl.text.trim(),
        newPassword: _passCtrl.text,
      );

      if (!mounted) return;

      AppMessage.success(context, l10n.forgotPasswordSuccess);
      Navigator.of(context).pop(_email);
    } catch (e) {
      if (!mounted) return;
      AppMessage.apiError(
        context,
        e,
        fallback: l10n.forgotPasswordConfirmError,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendIn = _resendCooldownSeconds);

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _resendIn--);

      if (_resendIn <= 0) timer.cancel();
    });
  }

  void _backToEmailStep() {
    _resendTimer?.cancel();

    setState(() {
      _codeSent = false;
      _resendIn = 0;
      _codeCtrl.clear();
      _passCtrl.clear();
      _confirmCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AuthDialogColors.modal,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AuthDialogColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                      child: _codeSent ? _buildResetStep() : _buildEmailStep(),
                    ),
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
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AuthDialogColors.header,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AuthDialogColors.border)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36),
          const Spacer(),
          Text(
            l10n.forgotPassword,
            style: const TextStyle(
              color: AuthDialogColors.whiteText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AuthDialogColors.closeButton,
                shape: BoxShape.circle,
                border: Border.all(color: AuthDialogColors.closeButtonBorder),
              ),
              child: const Icon(
                Icons.close,
                color: AuthDialogColors.whiteText,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _description(l10n.forgotPasswordEmailStep),
          const SizedBox(height: 18),
          _label(l10n.email),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgotPasswordEmail'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hintText: l10n.emailHint,
              prefixIcon: Icons.mail_outline,
            ),
            onFieldSubmitted: (_) => _sendCode(),
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return l10n.requiredEmail;
              if (!value.contains('@')) return l10n.invalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 22),
          _primaryButton(
            label: l10n.forgotPasswordSendCode,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _description(l10n.forgotPasswordCodeStep(_email)),
          const SizedBox(height: 18),
          _label(l10n.forgotPasswordCode),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgotPasswordCode'),
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: _inputTextStyle.copyWith(letterSpacing: 4),
            decoration: _inputDecoration(
              hintText: '000000',
              prefixIcon: Icons.pin_outlined,
            ),
            validator: (v) {
              final value = (v ?? '').trim();
              if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                return l10n.forgotPasswordInvalidCode;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _label(l10n.forgotPasswordNewPassword),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgotPasswordNewPassword'),
            controller: _passCtrl,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.newPassword],
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hintText: l10n.forgotPasswordNewPassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                splashRadius: 18,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AuthDialogColors.mutedText,
                  size: 22,
                ),
              ),
            ),
            validator: (v) {
              final value = v ?? '';
              if (value.isEmpty) return l10n.requiredPassword;
              if (value.length < 6) return l10n.forgotPasswordPasswordTooShort;
              return null;
            },
          ),
          const SizedBox(height: 16),
          _label(l10n.forgotPasswordConfirmPassword),
          const SizedBox(height: 8),
          TextFormField(
            key: const Key('forgotPasswordConfirmPassword'),
            controller: _confirmCtrl,
            obscureText: _obscure,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hintText: l10n.forgotPasswordConfirmPassword,
              prefixIcon: Icons.lock_outline,
            ),
            onFieldSubmitted: (_) => _confirm(),
            validator: (v) {
              if ((v ?? '') != _passCtrl.text) {
                return l10n.forgotPasswordPasswordMismatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          _primaryButton(label: l10n.forgotPasswordSubmit, onPressed: _confirm),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TextButton(
                onPressed: _loading ? null : _backToEmailStep,
                child: Text(
                  l10n.forgotPasswordChangeEmail,
                  style: const TextStyle(color: AuthDialogColors.mutedText),
                ),
              ),
              TextButton(
                onPressed: _loading || _resendIn > 0
                    ? null
                    : () => _sendCode(isResend: true),
                child: Text(
                  _resendIn > 0
                      ? l10n.forgotPasswordResendIn(_resendIn)
                      : l10n.forgotPasswordResend,
                  style: TextStyle(
                    color: _resendIn > 0
                        ? AuthDialogColors.hintText
                        : AuthDialogColors.linkBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static const TextStyle _inputTextStyle = TextStyle(
    color: AuthDialogColors.whiteText,
    fontSize: 15,
  );

  Widget _description(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AuthDialogColors.mutedText,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AuthDialogColors.whiteText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthDialogColors.primaryBlue,
          disabledBackgroundColor: AuthDialogColors.primaryBlueDisabled,
          foregroundColor: AuthDialogColors.whiteText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AuthDialogColors.whiteText,
                  ),
                ),
              )
            : Text(label),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: AuthDialogColors.hintText,
        fontSize: 15,
      ),
      filled: true,
      fillColor: AuthDialogColors.inputFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      prefixIcon: Icon(prefixIcon, color: AuthDialogColors.mutedText, size: 20),
      suffixIcon: suffixIcon,
      enabledBorder: border(AuthDialogColors.border),
      focusedBorder: border(AuthDialogColors.whiteText),
      errorBorder: border(AuthDialogColors.dangerRed),
      focusedErrorBorder: border(AuthDialogColors.dangerRed),
      border: border(AuthDialogColors.border),
    );
  }
}
