// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get homeTitle => 'Home';

  @override
  String get loggedSuccessfully => 'Logado com sucesso.';

  @override
  String get selectLanguage => 'Selecionar idioma';

  @override
  String get signIn => 'Entrar';

  @override
  String get favoritesLabel => 'Favoritos';

  @override
  String get accessAccount => 'Acessar conta';

  @override
  String get continueWith => 'Continuar com';

  @override
  String get or => 'ou';

  @override
  String get email => 'Email';

  @override
  String get emailOrPhone => 'Email';

  @override
  String get emailHint => 'Informe seu email';

  @override
  String get emailOrPhoneHint => 'Informe o email';

  @override
  String get password => 'Senha';

  @override
  String get passwordHint => 'Informe sua senha';

  @override
  String get forgotPassword => 'Recuperar senha';

  @override
  String get access => 'Acessar';

  @override
  String get dontHaveAccount => 'Não possui uma conta?';

  @override
  String get signUp => 'Cadastre-se';

  @override
  String get termsPrefix => 'Acessando você concorda com o';

  @override
  String get termsOfUse => 'termo de uso';

  @override
  String get registerTitle => 'Cadastro';

  @override
  String get fullName => 'Nome completo';

  @override
  String get fullNameHint => 'Informe seu nome e sobrenome';

  @override
  String get registerButton => 'Cadastrar';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get goToLogin => 'Acesse';

  @override
  String get requiredEmail => 'Email é obrigatório';

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get requiredPassword => 'Senha é obrigatória';

  @override
  String get requiredFullName => 'Nome completo é obrigatório';

  @override
  String get invalidFullName => 'Informe um nome válido';

  @override
  String get minimumPassword => 'A senha precisa ter no mínimo 4 caracteres';

  @override
  String get loginError => 'Erro durante o login';

  @override
  String get registerError => 'Erro durante o cadastro';

  @override
  String get registerSuccess => 'Usuário cadastrado com sucesso.';

  @override
  String get logout => 'Sair';

  @override
  String get loginRequiredForAppointments =>
      'Voce precisa estar logado para visualizar seus agendamentos.';

  @override
  String get findABusinessHint => 'Encontre um estabelecimento';

  @override
  String get allCompanyTypes => 'Todos';

  @override
  String get errorLoadingBusinesses => 'Erro ao buscar estabelecimentos.';

  @override
  String get noBusinessesFound => 'Nenhum estabelecimento encontrado';

  @override
  String get tryChangingFilter =>
      'Tente alterar o filtro ou buscar outro nome.';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get navHome => 'Inicio';

  @override
  String get navSearch => 'Buscar';

  @override
  String get navMyAppointments => 'Meus Agendamentos';

  @override
  String get welcomeMessage => 'Seja bem vindo(a)';

  @override
  String get nearbyBusinesses => 'Empresas proximas';

  @override
  String get forgotPasswordEmailStep =>
      'Informe o e-mail da sua conta. Vamos enviar um código de 6 dígitos para você criar uma nova senha.';

  @override
  String get forgotPasswordSendCode => 'Enviar código';

  @override
  String forgotPasswordCodeStep(String email) {
    return 'Se existir uma conta com $email, enviamos um código para esse e-mail. Ele vale por 15 minutos.';
  }

  @override
  String get forgotPasswordCode => 'Código';

  @override
  String get forgotPasswordInvalidCode => 'O código deve ter 6 dígitos';

  @override
  String get forgotPasswordNewPassword => 'Nova senha';

  @override
  String get forgotPasswordConfirmPassword => 'Confirmar nova senha';

  @override
  String get forgotPasswordPasswordTooShort =>
      'A senha deve ter pelo menos 6 caracteres';

  @override
  String get forgotPasswordPasswordMismatch => 'As senhas não conferem';

  @override
  String get forgotPasswordSubmit => 'Redefinir senha';

  @override
  String get forgotPasswordResend => 'Reenviar código';

  @override
  String forgotPasswordResendIn(int seconds) {
    return 'Reenviar código em ${seconds}s';
  }

  @override
  String get forgotPasswordChangeEmail => 'Usar outro e-mail';

  @override
  String get forgotPasswordCodeSent =>
      'Código enviado. Confira sua caixa de entrada e o spam.';

  @override
  String get forgotPasswordSuccess => 'Senha alterada! Entre com a nova senha.';

  @override
  String get forgotPasswordRequestError =>
      'Não foi possível enviar o código. Tente novamente.';

  @override
  String get forgotPasswordConfirmError =>
      'Não foi possível redefinir a senha. Tente novamente.';
}
