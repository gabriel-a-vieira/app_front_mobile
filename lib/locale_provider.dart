import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = Locale('pt', 'BR');  // Idioma inicial

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    print('Alterando idioma para: ${locale.languageCode}');  // Debugging
    if (_locale != locale) {
      _locale = locale;
      print('Alterando idioma para: ${_locale.languageCode}');  // Debugging
      notifyListeners();
      print('Listeners notificados');  // Debugging
    }
  }
}