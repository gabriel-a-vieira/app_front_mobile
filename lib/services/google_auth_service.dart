import 'dart:async';

import 'package:app_front_mobile/services/auth_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_front_mobile/config/api_config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final AuthService _authService = AuthService(baseUrl: ApiConfig.baseUrl);

  final TokenStorage _tokenStorage = TokenStorage();

  final StreamController<AuthLoginResult> _successController =
      StreamController<AuthLoginResult>.broadcast();

  final StreamController<Object> _errorController =
      StreamController<Object>.broadcast();

  Stream<AuthLoginResult> get successStream => _successController.stream;

  Stream<Object> get errorStream => _errorController.stream;

  bool _initialized = false;

  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _authenticationSubscription;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _googleSignIn.initialize();

    _authenticationSubscription = _googleSignIn.authenticationEvents.listen(
      _handleAuthenticationEvent,
      onError: (Object error, StackTrace stackTrace) {
        _errorController.add(error);
      },
    );

    _initialized = true;
  }

  Future<void> authenticateInteractive() async {
    await initialize();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw StateError('Esta plataforma requer o botao oficial do Google.');
    }

    try {
      await _googleSignIn.authenticate();
    } catch (e) {
      _errorController.add(e);
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) {
      return;
    }

    try {
      final account = event.user;

      final authentication = account.authentication;

      final idToken = authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google não retornou um ID Token.');
      }

      /*
       * Enviamos o token Google apenas
       * para o endpoint de autenticação.
       */
      final result = await _authService.externalLogin(
        provider: 'GOOGLE',
        credential: idToken,
      );

      /*
       * Depois disso guardamos somente
       * o JWT gerado pelo Softix.
       */
      await _tokenStorage.saveAccessToken(result.token);

      _successController.add(result);
    } catch (e) {
      _errorController.add(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // O logout do Softix não deve
      // falhar caso o Google já esteja
      // desconectado.
    }
  }

  Future<void> dispose() async {
    await _authenticationSubscription?.cancel();

    await _successController.close();

    await _errorController.close();
  }
}
