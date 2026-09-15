import 'package:flutter/material.dart';

/// Named tokens for the dark-mode colors repeated (as raw hex literals)
/// across dozens of pages/widgets. Every call site did
/// `isDark ? const Color(0xFF11141B) : colorScheme.surface` (or similar)
/// by hand - this only gives those already-consistent values a name, it
/// does not change any of them, so it carries no visual difference.
///
/// This is a first step, not a full design system: many other colors in
/// the app are still one-off literals (brand colors, status accents) that
/// weren't repeated enough to justify a token yet.
class AppColors {
  AppColors._();

  /// Dark-mode equivalent of `colorScheme.surface` - card/list container
  /// backgrounds.
  static const Color darkSurface = Color(0xFF11141B);

  /// Dark-mode equivalent of `colorScheme.surfaceContainerHighest` - dialog
  /// backgrounds and grid header rows (slightly lighter than [darkSurface]).
  static const Color darkSurfaceElevated = Color(0xFF171A22);

  /// Dark-mode fill color for filled text fields.
  static const Color darkInputFill = Color(0xFF1C212B);
}
