import 'package:app_front_mobile/pages/login_page.dart';
import 'package:app_front_mobile/pages/register_page.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../locale_provider.dart';

class LanguageOption {
  final Locale locale;
  final String countryCode;
  final String shortLabel;
  final String fullLabel;

  const LanguageOption({
    required this.locale,
    required this.countryCode,
    required this.shortLabel,
    required this.fullLabel,
  });
}

const List<LanguageOption> languageOptions = [
  LanguageOption(
    locale: Locale('pt', 'BR'),
    countryCode: 'BR',
    shortLabel: 'BR',
    fullLabel: 'Portugues - Brasil',
  ),
  LanguageOption(
    locale: Locale('en', 'US'),
    countryCode: 'US',
    shortLabel: 'USA',
    fullLabel: 'English - United States',
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openLoginModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LoginPage(
            onLoginSuccess: () {
              Navigator.of(dialogContext).pop();
            },
            onRegisterTap: () {
              Navigator.of(dialogContext).pop();
              _openRegisterModal(context);
            },
          ),
        );
      },
    );
  }

  void _openRegisterModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: RegisterPage(
            onLoginTap: () {
              Navigator.of(dialogContext).pop();
              _openLoginModal(context);
            },
            onRegisterSuccess: () {
              Navigator.of(dialogContext).pop();
              _openLoginModal(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final menuBackgroundColor = isDark
        ? const Color(0xFF17191E)
        : colorScheme.surface;

    final menuBorderColor = isDark
        ? const Color(0xFF2C313A)
        : colorScheme.outline.withOpacity(0.35);

    final textColor = colorScheme.onSurface;
    final mutedColor = colorScheme.onSurface.withOpacity(0.65);
    final selectedColor = colorScheme.primary;

    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;

    final selectedLanguage = languageOptions.firstWhere(
      (option) =>
          option.locale.languageCode == currentLocale.languageCode &&
          option.locale.countryCode == currentLocale.countryCode,
      orElse: () => languageOptions.first,
    );

    return PopupMenuButton<LanguageOption>(
      tooltip: l10n.selectLanguage,
      color: menuBackgroundColor,
      elevation: 8,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: menuBorderColor,
          width: 1,
        ),
      ),
      onSelected: (LanguageOption option) {
        final localeProvider = Provider.of<LocaleProvider>(
          context,
          listen: false,
        );

        localeProvider.setLocale(option.locale);
      },
      itemBuilder: (context) {
        return languageOptions.map((option) {
          final isSelected =
              option.locale.languageCode ==
                      selectedLanguage.locale.languageCode &&
                  option.locale.countryCode ==
                      selectedLanguage.locale.countryCode;

          return PopupMenuItem<LanguageOption>(
            value: option,
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 4,
            ),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: isSelected
                    ? Border.all(
                        color: selectedColor,
                        width: 1.5,
                      )
                    : null,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CountryFlag.fromCountryCode(
                    option.countryCode,
                    theme: const ImageTheme(
                      width: 24,
                      height: 18,
                      shape: RoundedRectangle(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      option.fullLabel,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_outline,
                      color: selectedColor,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            CountryFlag.fromCountryCode(
              selectedLanguage.countryCode,
              theme: const ImageTheme(
                width: 24,
                height: 18,
                shape: RoundedRectangle(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              selectedLanguage.shortLabel,
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor ??
                    colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              color: mutedColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () {
        _openLoginModal(context);
      },
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.only(right: 12, left: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.person_outline,
                color: colorScheme.onSurface,
                size: 20,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.signIn,
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor ??
                    colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final themeNotifier = Provider.of<ThemeNotifier>(
                context,
                listen: false,
              );
              themeNotifier.toggleTheme();
            },
          ),
          _buildLanguageSelector(context),
          _buildLoginButton(context),
        ],
      ),
      body: Center(
        child: Text(l10n.loggedSuccessfully),
      ),
    );
  }
}