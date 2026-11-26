import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kleine lokale Einstellungen des Geräts (keine Geschäftsdaten).
final class AppPreferences {
  const AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingKey = 'onboarding_done';

  /// Die Einführung wurde gesehen oder übersprungen.
  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> markOnboardingDone() => _prefs.setBool(_onboardingKey, true);

  static const _languageKey = 'language_code';

  /// Gewählte Sprache (`de`, `ar`) oder `null` = Sprache des Geräts.
  String? get languageCode => _prefs.getString(_languageKey);

  Future<void> setLanguageCode(String? code) => code == null
      ? _prefs.remove(_languageKey)
      : _prefs.setString(_languageKey, code);

  /// Angefangene Formulare (JSON-Text), nur auf diesem Gerät; siehe
  /// `FormDrafts`.
  String? draft(String key) => _prefs.getString('draft.$key');

  Future<void> saveDraft(String key, String json) =>
      _prefs.setString('draft.$key', json);

  Future<void> removeDraft(String key) => _prefs.remove('draft.$key');
}

/// Wird in `main` mit der geladenen Instanz überschrieben.
final appPreferencesProvider = Provider<AppPreferences>(
  (ref) => throw UnimplementedError('appPreferencesProvider nicht gesetzt'),
);
