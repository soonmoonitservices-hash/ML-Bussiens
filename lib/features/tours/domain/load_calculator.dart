import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

/// Eine Position der Beladung mit den kopierten Preisen.
final class LoadLine {
  /// Erzeugt eine Beladungsposition.
  const LoadLine({
    required this.quantity,
    required this.buyPrice,
    required this.sellPrice,
  });

  /// Geladene Menge.
  final Quantity quantity;

  /// Netto-Einkaufspreis pro Basiseinheit (bei kg pro Kilogramm).
  final Money buyPrice;

  /// Netto-Verkaufspreis pro Basiseinheit (bei kg pro Kilogramm).
  final Money sellPrice;
}

/// Summen einer Beladung.
final class LoadSummary {
  /// Erzeugt die Summen.
  const LoadSummary({required this.costValue, required this.sellValue});

  /// Warenwert zum Einkaufspreis.
  final Money costValue;

  /// Warenwert zum Verkaufspreis.
  final Money sellValue;

  /// Erwarteter Gewinn, wenn alles verkauft wird.
  Money get expectedProfit => sellValue - costValue;
}

/// Rechnet den Wert der Ladung für die Live-Anzeige (maßgeblich ist die DB).
final class LoadCalculator {
  /// Erzeugt den Rechner.
  const LoadCalculator();

  /// Summiert Einkaufs- und Verkaufswert aller Positionen.
  LoadSummary summarize(List<LoadLine> lines) {
    var cost = Money.zero;
    var sell = Money.zero;
    for (final line in lines) {
      cost += line.quantity.valueAt(line.buyPrice);
      sell += line.quantity.valueAt(line.sellPrice);
    }
    return LoadSummary(costValue: cost, sellValue: sell);
  }
}
