import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  // Configuração do backend
  final _authService = AuthService(baseUrl: 'http://localhost:8081');
  final _tokenStorage = TokenStorage();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      context.go('/'); // Navega para a home
    } catch (e) {
      if (!mounted) return;

      // Exibe erro se o login falhar
      print("Erro durante o login: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Check credentials.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        // Adiciona rolagem ao conteúdo
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrar',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Botões de login social
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botão do Google
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.g_mobiledata), // Ícone do Google
                    label: const Text('Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, // Cor do Google
                      minimumSize: const Size(
                        120,
                        40,
                      ), // Tamanho mínimo do botão
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão do Facebook
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.facebook),
                    label: const Text('Facebook'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent, // Cor do Facebook
                      minimumSize: const Size(
                        120,
                        40,
                      ), // Tamanho mínimo do botão
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão da Apple
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Cor da Apple
                      minimumSize: const Size(
                        120,
                        40,
                      ), // Tamanho mínimo do botão
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('ou', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            // Campo de email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Email é obrigatório';
                if (!value.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Campo de senha
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return 'Senha é obrigatória';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Botão de login
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
