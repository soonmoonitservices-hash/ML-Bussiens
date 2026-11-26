import 'package:warenbestand/core/value_objects/money.dart';

/// Erlaubte Umsatzsteuersätze.
enum VatRate {
  /// Steuerfrei (z. B. Kleinunternehmer oder Beleg ohne USt).
  zero(0),

  /// Ermäßigter Satz (Lebensmittel).
  reduced(7),

  /// Regelsatz.
  standard(19);

  const VatRate(this.percent);

  /// Satz in Prozent.
  final int percent;

  /// Findet den Satz zur Prozentzahl aus der Datenbank.
  static VatRate fromPercent(int percent) =>
      VatRate.values.firstWhere((rate) => rate.percent == percent);

  /// Brutto aus Netto, USt gerundet wie in der Datenbank (`gross_cents`).
  Money grossFromNet(Money net) => net + net.percent(percent);

  /// Netto aus Brutto wie in der Datenbank (`net_from_gross_cents`).
  Money netFromGross(Money gross) =>
      Money(roundHalfAwayFromZero(gross.cents * 100, 100 + percent));
}
