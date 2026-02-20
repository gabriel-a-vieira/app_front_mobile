import 'package:flutter/material.dart';
import '../storage/token_storage.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await tokenStorage.clear();
              if (context.mounted) {
                Navigator.of(context).pushNamed('/login');
              }
            },
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: const Center(
        child: Text('Logado com sucesso.'),
      ),
    );
  }
}