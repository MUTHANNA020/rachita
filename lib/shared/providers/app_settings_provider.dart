import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider unimplemented in main.dart');
});

class AppSettings {
  final ThemeMode themeMode;
  final Locale locale;

  AppSettings({required this.themeMode, required this.locale});

  AppSettings copyWith({ThemeMode? themeMode, Locale? locale}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;

  AppSettingsNotifier(this._prefs)
      : super(AppSettings(
          themeMode: _prefs.getBool('isDarkMode') == true
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: Locale(_prefs.getString('languageCode') ?? 'ar'),
        ));

  void toggleTheme(bool isDark) {
    _prefs.setBool('isDarkMode', isDark);
    state = state.copyWith(themeMode: isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void changeLanguage(String languageCode) {
    _prefs.setString('languageCode', languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }
}

final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppSettingsNotifier(prefs);
});
