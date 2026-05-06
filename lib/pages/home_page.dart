import 'package:app_front_mobile/pages/login_page.dart';
import 'package:app_front_mobile/pages/register_page.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    fullLabel: 'Português - Brasil',
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
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale;

    final selectedLanguage = languageOptions.firstWhere(
      (option) =>
          option.locale.languageCode == currentLocale.languageCode &&
          option.locale.countryCode == currentLocale.countryCode,
      orElse: () => languageOptions.first,
    );

    return PopupMenuButton<LanguageOption>(
      tooltip: 'Selecionar idioma',
      color: const Color(0xFF17191E),
      elevation: 8,
      offset: const Offset(0, 42),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF2C313A),
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
                        color: const Color(0xFF0089F7),
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
                      style: const TextStyle(
                        color: Color(0xFFF5F7FA),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF0089F7),
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
              style: const TextStyle(
                color: Color(0xFFF5F7FA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFF9EA6B2),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return InkWell(
      onTap: () {
        _openLoginModal(context);
      },
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.only(right: 12, left: 4),
        child: Row(
          children: const [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF2A2F38),
              child: Icon(
                Icons.person_outline,
                color: Color(0xFFF5F7FA),
                size: 20,
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Entrar',
              style: TextStyle(
                color: Color(0xFFF5F7FA),
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
    return Scaffold(
      backgroundColor: const Color(0xFF050609),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050609),
        elevation: 0,
        title: const Text('Home'),
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
      body: const Center(
        child: Text('Logado com sucesso.'),
      ),
    );
  }
}