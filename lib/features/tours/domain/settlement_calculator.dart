import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Eine Tour-Position für die Abrechnung.
final class SettlementLine {
  /// Erzeugt eine Abrechnungsposition.
  const SettlementLine({
    required this.loaded,
    required this.returned,
    required this.buyPrice,
    required this.sellPrice,
    required this.vatRate,
    this.gift,
    this.removedRevenue = Money.zero,
    this.removedCost = Money.zero,
  });

  /// Geladene Menge.
  final Quantity loaded;

  /// Zurückgebrachte Menge.
  final Quantity returned;

  /// Netto-Einkaufspreis (kopiert).
  final Money buyPrice;

  /// Netto-Verkaufspreis (kopiert).
  final Money sellPrice;

  /// Umsatzsteuersatz der Position.
  final VatRate vatRate;

  /// Verschenkte Menge (kein Umsatz, Einkaufspreis zählt als Wareneinsatz).
  final Quantity? gift;

  /// Verschenkte Menge, 0 wenn nichts verschenkt wird.
  Quantity get giftQty => gift ?? Quantity.zero(loaded.unit);

  /// Verkaufswert der aus einem Karton entfernten Produkte (mindert den Umsatz).
  final Money removedRevenue;

  /// Einkaufswert der aus einem Karton zurückgebrachten Produkte (mindert den
  /// Wareneinsatz).
  final Money removedCost;

  /// Ware, die das Lager verlassen hat = geladen − zurück.
  Quantity get sold => loaded - returned;

  /// Bezahlte Menge = geladen − zurück − geschenkt (Basis für den Umsatz).
  Quantity get billed => sold - giftQty;
}

/// Eine Ausgabe während der Tour.
final class SettlementExpense {
  /// Erzeugt eine Ausgabe.
  const SettlementExpense({required this.gross, this.vatRate = VatRate.zero});

  /// Bruttobetrag laut Beleg.
  final Money gross;

  /// In der Ausgabe enthaltener Steuersatz.
  final VatRate vatRate;
}

/// Die Rückgabe ist größer als die Ladung.
final class ReturnExceedsLoadException implements Exception {
  /// Erzeugt den Fehler.
  const ReturnExceedsLoadException();
}

/// Ergebnis der Tour-Abrechnung.
final class Settlement {
  /// Erzeugt das Ergebnis.
  const Settlement({
    required this.revenueNet,
    required this.revenueGross,
    required this.cost,
    required this.expensesGross,
    required this.expensesNet,
    required this.expectedCash,
    required this.difference,
  });

  /// Verkaufswert netto.
  final Money revenueNet;

  /// Verkaufswert brutto (mit USt).
  final Money revenueGross;

  /// Wareneinsatz (Menge, die das Lager verlassen hat, × Einkaufspreis; Geschenke zählen mit).
  final Money cost;

  /// Summe der Ausgaben brutto.
  final Money expensesGross;

  /// Summe der Ausgaben netto.
  final Money expensesNet;

  /// Soll-Bargeld = Verkaufswert − Ausgaben.
  final Money expectedCash;

  /// Übergebenes Bargeld − Soll-Bargeld.
  final Money difference;

  /// Tourgewinn = Umsatz netto − Wareneinsatz − Ausgaben netto + Differenz.
  /// Das übergebene Bargeld geht in den Gewinn ein: Ein Mehr- oder
  /// Wenigerbetrag zählt direkt dazu.
  Money get profit => revenueNet - cost - expensesNet + difference;

  /// Ob die Kasse stimmt.
  bool get isBalanced => difference.isZero;
}

/// Rechnet die Tour-Abrechnung für die Live-Anzeige (maßgeblich ist
/// `close_tour` in der Datenbank).
final class SettlementCalculator {
  /// Erzeugt den Rechner.
  const SettlementCalculator();

  /// Berechnet die Abrechnung. Wirft [ReturnExceedsLoadException], wenn bei
  /// einer Position mehr zurückkam als geladen wurde.
  Settlement calculate({
    required List<SettlementLine> lines,
    required List<SettlementExpense> expenses,
    required Money cashReceived,
    required bool cashIncludesVat,
  }) {
    var net = Money.zero;
    var gross = Money.zero;
    var cost = Money.zero;
    for (final line in lines) {
      if ((line.returned + line.giftQty) > line.loaded) {
        throw const ReturnExceedsLoadException();
      }
      final lineNet = line.billed.valueAt(line.sellPrice) - line.removedRevenue;
      net += lineNet;
      gross += line.vatRate.grossFromNet(lineNet);
      cost += line.sold.valueAt(line.buyPrice) - line.removedCost;
    }
    final expensesGross = expenses.fold(Money.zero, (sum, e) => sum + e.gross);
    final expensesNet = expenses.fold(
      Money.zero,
      (sum, e) => sum + e.vatRate.netFromGross(e.gross),
    );
    final expectedCash = (cashIncludesVat ? gross : net) - expensesGross;
    return Settlement(
      revenueNet: net,
      revenueGross: gross,
      cost: cost,
      expensesGross: expensesGross,
      expensesNet: expensesNet,
      expectedCash: expectedCash,
      difference: cashReceived - expectedCash,
    );
  }
}
