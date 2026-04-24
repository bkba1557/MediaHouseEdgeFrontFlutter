import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_localizations.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'preferred_locale_code';

  Locale _locale = AppLocalizations.supportedLocales.first;

  LocaleProvider() {
    _loadSavedLocale();
  }

  Locale get locale => _locale;

  bool get isRtl => AppLocalizations.isRtlLocale(_locale);

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_storageKey);
    if (code == null || code.trim().isEmpty) return;
    final match = AppLocalizations.supportedLocales.where(
      (locale) => locale.languageCode == code,
    );
    if (match.isEmpty) return;
    _locale = match.first;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.contains(locale)) return;
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
  }
}
