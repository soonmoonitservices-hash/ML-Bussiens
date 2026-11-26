/// Geldbetrag in Cent. Nie als double speichern oder rechnen.
final class Money implements Comparable<Money> {
  /// Erzeugt einen Betrag aus ganzen Cent.
  const Money(this.cents);

  /// Betrag 0.
  static const Money zero = Money(0);

  /// Betrag in Cent (negativ erlaubt, z. B. für Fehlbeträge).
  final int cents;

  /// Liest Eingaben wie „12,50“, „12.50“ oder „1.234,56“. Maximal zwei
  /// Nachkommastellen; sonst `null`.
  static Money? tryParse(String input) {
    final text = input.trim().replaceAll(' ', '').replaceAll('€', '');
    final match = RegExp(r'^(-?)(\d+(?:[.,]\d+)*)$').firstMatch(text);
    if (match == null) {
      return null;
    }
    final isNegative = match.group(1) == '-';
    final digits = _normalizeSeparators(match.group(2)!);
    if (digits == null) {
      return null;
    }
    final parts = digits.split('.');
    final fraction = parts.length == 2 ? parts[1] : '';
    if (fraction.length > 2) {
      return null;
    }
    final cents =
        int.parse(parts[0]) * 100 + int.parse(fraction.padRight(2, '0'));
    return Money(isNegative ? -cents : cents);
  }

  /// Letztes Trennzeichen ist das Komma; davor stehende Trenner sind
  /// Tausenderpunkte. Ein einzelner Punkt zählt als Dezimalpunkt.
  static String? _normalizeSeparators(String value) {
    final lastSeparator = value.lastIndexOf(RegExp('[.,]'));
    if (lastSeparator < 0) {
      return value;
    }
    final integerPart = value
        .substring(0, lastSeparator)
        .replaceAll(RegExp('[.,]'), '');
    return '$integerPart.${value.substring(lastSeparator + 1)}';
  }

  /// Summe.
  Money operator +(Money other) => Money(cents + other.cents);

  /// Differenz.
  Money operator -(Money other) => Money(cents - other.cents);

  /// Vorzeichen umkehren.
  Money operator -() => Money(-cents);

  /// Vielfaches (z. B. Stückzahl × Einzelpreis).
  Money times(int factor) => Money(cents * factor);

  /// Ob der Betrag kleiner als 0 ist.
  bool get isNegative => cents < 0;

  /// Ob der Betrag genau 0 ist.
  bool get isZero => cents == 0;

  /// Kaufmännisch gerundeter Prozentanteil (wie `round()` in der Datenbank).
  Money percent(int rate) => Money(_roundHalfAwayFromZero(cents * rate, 100));

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => 'Money($cents)';
}

/// Ganzzahl-Division mit Rundung „halb weg von null“ wie PostgreSQL `round`.
int roundHalfAwayFromZero(int numerator, int denominator) =>
    _roundHalfAwayFromZero(numerator, denominator);

int _roundHalfAwayFromZero(int numerator, int denominator) {
  final absolute = numerator.abs();
  final quotient = (absolute * 2 + denominator) ~/ (denominator * 2);
  return numerator < 0 ? -quotient : quotient;
}
