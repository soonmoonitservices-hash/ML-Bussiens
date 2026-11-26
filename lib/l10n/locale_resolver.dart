import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Übersetzungen der App plus die von Material, Cupertino und Widgets
/// (Schreibrichtung, Datumsauswahl, Tooltips). Die von `gen-l10n` erzeugte
/// Liste nutzt die veraltete Variante aus `flutter_localizations`.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// Wählt die Sprache der App: Arabisch, wenn das Gerät Arabisch nutzt, sonst
/// Deutsch.
Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supportedLocales) {
  final code = deviceLocale?.languageCode;
  for (final locale in AppLocalizations.supportedLocales) {
    if (locale.languageCode == code) return locale;
  }
  return const Locale('de');
}
