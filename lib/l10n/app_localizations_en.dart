// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeTitle => 'Home';

  @override
  String get loggedSuccessfully => 'Logged in successfully.';

  @override
  String get selectLanguage => 'Select language';

  @override
  String get signIn => 'Sign in';

  @override
  String get favoritesLabel => 'Favorites';

  @override
  String get accessAccount => 'Access account';

  @override
  String get continueWith => 'Continue with';

  @override
  String get or => 'or';

  @override
  String get email => 'Email';

  @override
  String get emailOrPhone => 'Email';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get emailOrPhoneHint => 'Enter your email';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get access => 'Sign in';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get termsPrefix => 'By accessing, you agree with the';

  @override
  String get termsOfUse => 'terms of use';

  @override
  String get registerTitle => 'Register';

  @override
  String get fullName => 'Full name';

  @override
  String get fullNameHint => 'Enter your full name';

  @override
  String get registerButton => 'Register';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get goToLogin => 'Sign in';

  @override
  String get requiredEmail => 'Email is required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get requiredPassword => 'Password is required';

  @override
  String get requiredFullName => 'Full name is required';

  @override
  String get invalidFullName => 'Enter a valid name';

  @override
  String get minimumPassword => 'Password must have at least 4 characters';

  @override
  String get loginError => 'Login error';

  @override
  String get registerError => 'Register error';

  @override
  String get registerSuccess => 'User registered successfully.';

  @override
  String get logout => 'Logout';

  @override
  String get loginRequiredForAppointments =>
      'You need to be logged in to view your appointments.';

  @override
  String get findABusinessHint => 'Find a business';

  @override
  String get allCompanyTypes => 'All';

  @override
  String get errorLoadingBusinesses => 'Error loading businesses.';

  @override
  String get noBusinessesFound => 'No businesses found';

  @override
  String get tryChangingFilter =>
      'Try changing the filter or searching another name.';

  @override
  String get loadMore => 'Load more';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navMyAppointments => 'My Appointments';

  @override
  String get welcomeMessage => 'Welcome';

  @override
  String get nearbyBusinesses => 'Nearby businesses';

  @override
  String get forgotPasswordEmailStep =>
      'Enter your account e-mail. We\'ll send you a 6-digit code to create a new password.';

  @override
  String get forgotPasswordSendCode => 'Send code';

  @override
  String forgotPasswordCodeStep(String email) {
    return 'If an account exists for $email, we sent a code to that e-mail. It is valid for 15 minutes.';
  }

  @override
  String get forgotPasswordCode => 'Code';

  @override
  String get forgotPasswordInvalidCode => 'The code must have 6 digits';

  @override
  String get forgotPasswordNewPassword => 'New password';

  @override
  String get forgotPasswordConfirmPassword => 'Confirm new password';

  @override
  String get forgotPasswordPasswordTooShort =>
      'Password must have at least 6 characters';

  @override
  String get forgotPasswordPasswordMismatch => 'Passwords don\'t match';

  @override
  String get forgotPasswordSubmit => 'Reset password';

  @override
  String get forgotPasswordResend => 'Resend code';

  @override
  String forgotPasswordResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get forgotPasswordChangeEmail => 'Use another e-mail';

  @override
  String get forgotPasswordCodeSent =>
      'Code sent. Check your inbox and spam folder.';

  @override
  String get forgotPasswordSuccess =>
      'Password changed! Sign in with your new password.';

  @override
  String get forgotPasswordRequestError =>
      'Couldn\'t send the code. Please try again.';

  @override
  String get forgotPasswordConfirmError =>
      'Couldn\'t reset the password. Please try again.';
}
