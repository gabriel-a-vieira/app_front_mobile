import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pt'),
    Locale('en'),
  ];

  /// No description provided for @homeTitle.
  ///
  /// In pt, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @loggedSuccessfully.
  ///
  /// In pt, this message translates to:
  /// **'Logado com sucesso.'**
  String get loggedSuccessfully;

  /// No description provided for @selectLanguage.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar idioma'**
  String get selectLanguage;

  /// No description provided for @signIn.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @accessAccount.
  ///
  /// In pt, this message translates to:
  /// **'Acessar conta'**
  String get accessAccount;

  /// No description provided for @continueWith.
  ///
  /// In pt, this message translates to:
  /// **'Continuar com'**
  String get continueWith;

  /// No description provided for @or.
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get or;

  /// No description provided for @email.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailOrPhone.
  ///
  /// In pt, this message translates to:
  /// **'Email'**
  String get emailOrPhone;

  /// No description provided for @emailHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu email'**
  String get emailHint;

  /// No description provided for @emailOrPhoneHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe o email'**
  String get emailOrPhoneHint;

  /// No description provided for @password.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe sua senha'**
  String get passwordHint;

  /// No description provided for @forgotPassword.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar senha'**
  String get forgotPassword;

  /// No description provided for @access.
  ///
  /// In pt, this message translates to:
  /// **'Acessar'**
  String get access;

  /// No description provided for @dontHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Não possui uma conta?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In pt, this message translates to:
  /// **'Cadastre-se'**
  String get signUp;

  /// No description provided for @termsPrefix.
  ///
  /// In pt, this message translates to:
  /// **'Acessando você concorda com o'**
  String get termsPrefix;

  /// No description provided for @termsOfUse.
  ///
  /// In pt, this message translates to:
  /// **'termo de uso'**
  String get termsOfUse;

  /// No description provided for @registerTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cadastro'**
  String get registerTitle;

  /// No description provided for @fullName.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu nome e sobrenome'**
  String get fullNameHint;

  /// No description provided for @registerButton.
  ///
  /// In pt, this message translates to:
  /// **'Cadastrar'**
  String get registerButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In pt, this message translates to:
  /// **'Já tem uma conta?'**
  String get alreadyHaveAccount;

  /// No description provided for @goToLogin.
  ///
  /// In pt, this message translates to:
  /// **'Acesse'**
  String get goToLogin;

  /// No description provided for @requiredEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email é obrigatório'**
  String get requiredEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In pt, this message translates to:
  /// **'Email inválido'**
  String get invalidEmail;

  /// No description provided for @requiredPassword.
  ///
  /// In pt, this message translates to:
  /// **'Senha é obrigatória'**
  String get requiredPassword;

  /// No description provided for @requiredFullName.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo é obrigatório'**
  String get requiredFullName;

  /// No description provided for @invalidFullName.
  ///
  /// In pt, this message translates to:
  /// **'Informe um nome válido'**
  String get invalidFullName;

  /// No description provided for @minimumPassword.
  ///
  /// In pt, this message translates to:
  /// **'A senha precisa ter no mínimo 4 caracteres'**
  String get minimumPassword;

  /// No description provided for @loginError.
  ///
  /// In pt, this message translates to:
  /// **'Erro durante o login'**
  String get loginError;

  /// No description provided for @registerError.
  ///
  /// In pt, this message translates to:
  /// **'Erro durante o cadastro'**
  String get registerError;

  /// No description provided for @registerSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Usuário cadastrado com sucesso.'**
  String get registerSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
