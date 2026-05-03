import 'package:app_front_mobile/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart'; // O ThemeNotifier para controlar o tema
import '../locale_provider.dart'; // O LocaleProvider para controlar o idioma

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          // Botão para alternar o tema
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              final themeNotifier = Provider.of<ThemeNotifier>(
                context,
                listen: false,
              );
              themeNotifier.toggleTheme();
            },
          ),

          // Botão para alternar o idioma
          PopupMenuButton(
            onSelected: (Locale locale) {
              final localeProvider = Provider.of<LocaleProvider>(
                context,
                listen: false,
              );
              localeProvider.setLocale(locale);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: Locale('pt', 'BR'),
                child: Row(
                  children: const [
                    Icon(Icons.flag), // Ícone da bandeira
                    SizedBox(width: 8),
                    Text('Português - Brasil'), // Texto do idioma
                  ],
                ),
              ),
              PopupMenuItem(
                value: Locale('en', 'US'),
                child: Row(
                  children: const [
                    Icon(Icons.flag), // Ícone da bandeira
                    SizedBox(width: 8),
                    Text('English - US'), // Texto do idioma
                  ],
                ),
              ),
              // Adicione outros idiomas conforme necessário
            ],
          ),

          // Botão de Login
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                barrierColor: Colors.black.withOpacity(0.65),
                builder: (context) {
                  return Dialog(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    insetPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: const LoginPage(),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: const Center(child: Text('Logado com sucesso.')),
    );
  }
}
