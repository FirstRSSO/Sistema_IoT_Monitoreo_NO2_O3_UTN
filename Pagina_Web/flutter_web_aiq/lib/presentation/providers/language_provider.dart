import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'es'].contains(locale.languageCode)) return;
    _locale = locale;
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'es' 
        ? const Locale('en') 
        : const Locale('es');
    notifyListeners();
  }
  
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isSpanish => _locale.languageCode == 'es';
}
