import 'package:flutter/services.dart';

/// Vibrationsrückmeldung: leicht bei Auswahl, mittel bei wichtigen Aktionen,
/// kräftig bei Erfolg, doppelt bei Fehler. Nie beim normalen Scrollen.
abstract final class Haptics {
  static void select() => HapticFeedback.selectionClick();
  static void action() => HapticFeedback.mediumImpact();
  static void success() => HapticFeedback.heavyImpact();
  static void error() => HapticFeedback.vibrate();
}
