import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:warenbestand/core/preferences/app_preferences.dart';

/// Die in der App gewählte Sprache. `null` heißt: Sprache des Geräts
/// (Arabisch, wenn das Gerät Arabisch nutzt, sonst Deutsch).
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = ref.read(appPreferencesProvider).languageCode;
    return code == null ? null : Locale(code);
  }

  Future<void> select(String? code) async {
    await ref.read(appPreferencesProvider).setLanguageCode(code);
    state = code == null ? null : Locale(code);
  }
}
