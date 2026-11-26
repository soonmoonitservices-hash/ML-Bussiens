import 'package:warenbestand/core/value_objects/money.dart';

/// Formatiert Geldbeträge deutsch: `1.234,56 €`.
abstract final class MoneyFormatter {
  static const _nbsp = '\u00A0';

  /// Betrag mit Tausenderpunkt, Komma und „€“ (z. B. `1.234,56 €`).
  /// Negative Beträge erhalten ein Minuszeichen vor der Zahl.
  static String format(Money money) =>
      '${formatPlain(money).replaceFirst('-', _minus)}$_nbsp€';

  /// Echtes Minuszeichen (U+2212) statt Bindestrich.
  static const _minus = '−';

  /// Wie [format], aber ohne Währungszeichen (für Tabellen und Eingabefelder).
  static String formatPlain(Money money) {
    final absolute = money.cents.abs();
    final euros = (absolute ~/ 100).toString();
    final cents = (absolute % 100).toString().padLeft(2, '0');
    final grouped = euros.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final sign = money.isNegative ? '-' : '';
    return '$sign$grouped,$cents';
  }

  /// Mit ausdrücklichem Vorzeichen (`+2,00 €`, `-8,00 €`), z. B. für Differenzen.
  static String formatSigned(Money money) =>
      money.cents > 0 ? '+${format(money)}' : format(money);
}
