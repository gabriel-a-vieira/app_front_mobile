import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Palette of the dark auth modals (login, "recuperar senha"). Values moved
/// as-is out of LoginPage's private constants so a second auth modal reuses
/// them instead of copying the same hex literals again - no visual change.
class AuthDialogColors {
  AuthDialogColors._();

  static const Color modal = AppColors.darkSurface;
  static const Color header = Color(0xFF1A1E26);
  static const Color border = Color(0xFF2A2F38);
  static const Color inputFill = AppColors.darkInputFill;
  static const Color primaryBlue = Color(0xFF0089F7);
  static const Color primaryBlueDisabled = Color(0xFF4D84B0);
  static const Color whiteText = Color(0xFFF5F7FA);
  static const Color mutedText = Color(0xFF9EA6B2);
  static const Color hintText = Color(0xFF8D95A3);
  static const Color linkBlue = Color(0xFF36A9FF);
  static const Color dangerRed = Color(0xFFFF5A5F);
  static const Color closeButton = Color(0xFF3A3F4A);
  static const Color closeButtonBorder = Color(0xFF4A505C);
}
