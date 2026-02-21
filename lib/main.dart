import 'package:app_front_mobile/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';  // O ThemeNotifier para controlar o tema
import 'locale_provider.dart';  // O LocaleProvider para controlar o idioma
import 'app_router.dart';  // Importando o arquivo que define o buildRouter

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),  // Provider para o tema
        ChangeNotifierProvider(create: (_) => LocaleProvider()),  // Provider para o idioma
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    final GoRouter router = buildRouter();

    return MaterialApp(
      title: 'Agenda App',
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // Definir diretamente a HomePage como tela inicial
      locale: localeProvider.locale,  // Definir o idioma
      supportedLocales: [
        Locale('pt', 'BR'),  // Suporte para Português
        Locale('en', 'US'),  // Suporte para Inglês
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeNotifier.themeMode,  // Definir o modo de tema
      theme: ThemeData.light(),  // Tema claro
      darkTheme: ThemeData.dark(),  // Tema escuro
    );
  }
}