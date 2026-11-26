import 'dart:ui';

/// Alle Farben der App. Schwarz-Weiß mit drei Statusfarben, sonst nichts.
abstract final class AppColors {
  /// Text, Buttons, Icons (kein reines Schwarz).
  static const ink = Color(0xFF0A0A0A);

  /// Hintergrund.
  static const paper = Color(0xFFFFFFFF);

  /// Eingabefelder, Filter-Leiste (leicht warmes Grau).
  static const paperMuted = Color(0xFFF5F5F5);

  /// Rahmen und Trennlinien.
  static const line = Color(0xFFE5E5E5);

  /// Nebentext.
  static const inkMuted = Color(0xFF6B6B6B);

  /// Platzhalter, deaktiviert.
  static const inkFaint = Color(0xFFA3A3A3);

  /// Erfolg: Text und Icon.
  static const success = Color(0xFF16A34A);

  /// Erfolg: Fläche.
  static const successSurface = Color(0xFFF0FDF4);

  /// Fehler: Text und Icon.
  static const error = Color(0xFFDC2626);

  /// Fehler: Fläche.
  static const errorSurface = Color(0xFFFEF2F2);

  /// Warnung: Text und Icon.
  static const warning = Color(0xFFD97706);

  /// Warnung: Fläche.
  static const warningSurface = Color(0xFFFFFBEB);

  /// Erfolgs-Häkchen auf dunklem Grund (Snackbar).
  static const successOnInk = Color(0xFF5BB98B);
}
