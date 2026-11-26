import 'package:flutter/widgets.dart';

/// Feste Zuordnung: immer dasselbe Icon für dasselbe Ding. Nur Phosphor
/// „Regular“, nie mit anderen Sets mischen.
///
/// Die Symbole stammen aus der Schrift des Pakets `phosphor_flutter`
/// (Familie `PhosphorRegular`). Dessen Dart-Klassen lassen sich mit der
/// aktuellen Flutter-Version nicht übersetzen (`IconData` ist dort `final`),
/// darum stehen die Codepunkte hier selbst.
abstract final class AppIcons {
  /// Standardgröße in der Oberfläche.
  static const double size = 22;

  /// Größe in der unteren Navigation.
  static const double navigationSize = 24;

  static const _family = 'PhosphorRegular';
  static const _package = 'phosphor_flutter';

  static const IconData tour = IconData(
    0xe4b4,
    fontFamily: _family,
    fontPackage: _package,
  ); // truck
  static const IconData stock = IconData(
    0xe390,
    fontFamily: _family,
    fontPackage: _package,
  ); // package
  static const IconData expense = IconData(
    0xe3ec,
    fontFamily: _family,
    fontPackage: _package,
  ); // receipt
  static const IconData deliveryNote = IconData(
    0xe23a,
    fontFamily: _family,
    fontPackage: _package,
  ); // file-text
  static const IconData invoice = IconData(
    0xee42,
    fontFamily: _family,
    fontPackage: _package,
  ); // invoice
  static const IconData signature = IconData(
    0xebac,
    fontFamily: _family,
    fontPackage: _package,
  ); // signature
  static const IconData driver = IconData(
    0xe9ac,
    fontFamily: _family,
    fontPackage: _package,
  ); // steering-wheel
  static const IconData report = IconData(
    0xe150,
    fontFamily: _family,
    fontPackage: _package,
  ); // chart-bar
  static const IconData more = IconData(
    0xe1fe,
    fontFamily: _family,
    fontPackage: _package,
  ); // dots-three
  static const IconData camera = IconData(
    0xe10e,
    fontFamily: _family,
    fontPackage: _package,
  ); // camera
  static const IconData share = IconData(
    0xeaf0,
    fontFamily: _family,
    fontPackage: _package,
  ); // export
  static const IconData pdf = IconData(
    0xe702,
    fontFamily: _family,
    fontPackage: _package,
  ); // file-pdf
  static const IconData search = IconData(
    0xe30c,
    fontFamily: _family,
    fontPackage: _package,
  ); // magnifying-glass
  static const IconData add = IconData(
    0xe3d4,
    fontFamily: _family,
    fontPackage: _package,
  ); // plus
  static const IconData minus = IconData(
    0xe32a,
    fontFamily: _family,
    fontPackage: _package,
  ); // minus
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: _family,
    fontPackage: _package,
  ); // warning
  static const IconData success = IconData(
    0xe184,
    fontFamily: _family,
    fontPackage: _package,
  ); // check-circle
  static const IconData error = IconData(
    0xe4f8,
    fontFamily: _family,
    fontPackage: _package,
  ); // x-circle
  static const IconData locked = IconData(
    0xe308,
    fontFamily: _family,
    fontPackage: _package,
  ); // lock-simple
  static const IconData calendar = IconData(
    0xe10a,
    fontFamily: _family,
    fontPackage: _package,
  ); // calendar-blank

  // Ergänzungen, die keine feste Zuordnung aus der Vorgabe haben.
  static const IconData home = IconData(
    0xe2c2,
    fontFamily: _family,
    fontPackage: _package,
  ); // house
  static const IconData user = IconData(
    0xe4c2,
    fontFamily: _family,
    fontPackage: _package,
  ); // user
  static const IconData users = IconData(
    0xe4d6,
    fontFamily: _family,
    fontPackage: _package,
  ); // users
  static const IconData company = IconData(
    0xe270,
    fontFamily: _family,
    fontPackage: _package,
  ); // gear
  static const IconData signOut = IconData(
    0xe42a,
    fontFamily: _family,
    fontPackage: _package,
  ); // sign-out
  static const IconData delete = IconData(
    0xe4a6,
    fontFamily: _family,
    fontPackage: _package,
  ); // trash
  static const IconData help = IconData(
    0xe3e8,
    fontFamily: _family,
    fontPackage: _package,
  ); // question
  static const IconData legal = IconData(
    0xe750,
    fontFamily: _family,
    fontPackage: _package,
  ); // scales

  static const IconData _caretLeft = IconData(
    0xe138,
    fontFamily: _family,
    fontPackage: _package,
  );
  static const IconData _caretRight = IconData(
    0xe13a,
    fontFamily: _family,
    fontPackage: _package,
  );

  /// Pfeil für „weiter“ in Listen; zeigt in RTL nach links.
  static IconData forward(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? _caretLeft
      : _caretRight;

  /// Zurück-Pfeil; zeigt in RTL nach rechts.
  static IconData back(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl
      ? _caretRight
      : _caretLeft;
}
