import 'package:flutter/material.dart';
import 'app_router.dart';  // Importando o arquivo que define o buildRouter

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();  // Agora o buildRouter será reconhecido

    return MaterialApp.router(
      title: 'Agenda App',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
      ),
    );
  }
}