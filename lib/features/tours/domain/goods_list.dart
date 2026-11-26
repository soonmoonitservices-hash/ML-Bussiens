import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

/// Eine Zeile der Warenliste: Produkt, Menge, Einzelpreis, Gesamtpreis.
final class GoodsLine {
  /// Erzeugt die Zeile.
  const GoodsLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });

  /// Produktname (bei entfernten Produkten aus einem Karton mit Hinweis).
  final String name;

  /// Menge in Basiseinheit.
  final Quantity quantity;

  /// Netto-Verkaufspreis pro Basiseinheit (bei kg pro Kilogramm).
  final Money unitPrice;

  /// Gesamtpreis der Zeile (bei abgezogenen Produkten negativ).
  final Money total;
}

/// Ein aus einem Karton entferntes Produkt.
final class GoodsRemovalInput {
  /// Erzeugt die Angabe.
  const GoodsRemovalInput({
    required this.label,
    required this.returned,
    required this.gift,
    required this.sellPrice,
  });

  /// Anzeigename, z. B. „Oliven (aus Probierkarton)“.
  final String label;

  /// Zurückgebrachte Menge.
  final Quantity returned;

  /// Verschenkte Menge.
  final Quantity gift;

  /// Netto-Verkaufspreis des enthaltenen Produkts.
  final Money sellPrice;
}

/// Eine Tour-Position für die Warenlisten.
final class GoodsInput {
  /// Erzeugt die Angabe.
  const GoodsInput({
    required this.name,
    required this.loaded,
    required this.returned,
    required this.gift,
    required this.sellPrice,
    this.removals = const [],
  });

  final String name;
  final Quantity loaded;
  final Quantity returned;
  final Quantity gift;
  final Money sellPrice;
  final List<GoodsRemovalInput> removals;
}

/// Baut die Listen „Verkaufte Ware“ und „Zurückgeholte Ware“ (nur für die
/// Anzeige und das PDF; die Summen der Tour kommen aus der Datenbank).
abstract final class GoodsLists {
  /// Bezahlte Ware: geladen − zurück − geschenkt, jeweils mit Einzel- und
  /// Gesamtpreis. Aus Kartons entfernte Produkte stehen als Abzug darunter.
  static List<GoodsLine> sold(List<GoodsInput> inputs) {
    final lines = <GoodsLine>[];
    for (final input in inputs) {
      final billed = input.loaded - input.returned - input.gift;
      if (billed.base > 0) {
        lines.add(
          GoodsLine(
            name: input.name,
            quantity: billed,
            unitPrice: input.sellPrice,
            total: billed.valueAt(input.sellPrice),
          ),
        );
      }
      for (final removal in input.removals) {
        final removed = Quantity(
          removal.returned.base + removal.gift.base,
          removal.returned.unit,
        );
        if (removed.base > 0) {
          lines.add(
            GoodsLine(
              name: removal.label,
              quantity: removed,
              unitPrice: removal.sellPrice,
              total: -removed.valueAt(removal.sellPrice),
            ),
          );
        }
      }
    }
    return lines;
  }

  /// Zurückgebrachte Ware mit Einzel- und Gesamtpreis (zum Verkaufspreis),
  /// auch einzelne Produkte, die aus Kartons zurückkamen.
  static List<GoodsLine> returned(List<GoodsInput> inputs) {
    final lines = <GoodsLine>[];
    for (final input in inputs) {
      if (input.returned.base > 0) {
        lines.add(
          GoodsLine(
            name: input.name,
            quantity: input.returned,
            unitPrice: input.sellPrice,
            total: input.returned.valueAt(input.sellPrice),
          ),
        );
      }
      for (final removal in input.removals) {
        if (removal.returned.base > 0) {
          lines.add(
            GoodsLine(
              name: removal.label,
              quantity: removal.returned,
              unitPrice: removal.sellPrice,
              total: removal.returned.valueAt(removal.sellPrice),
            ),
          );
        }
      }
    }
    return lines;
  }

  /// Summe der Gesamtpreise.
  static Money total(List<GoodsLine> lines) =>
      lines.fold(Money.zero, (sum, line) => sum + line.total);
}
