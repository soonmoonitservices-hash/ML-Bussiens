import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Eine Rechnungsposition.
final class InvoiceLine {
  /// Erzeugt eine Position.
  const InvoiceLine({
    required this.quantity,
    required this.priceNet,
    required this.vatRate,
  });

  /// Menge in Basiseinheit.
  final Quantity quantity;

  /// Netto-Einzelpreis pro Basiseinheit (bei kg pro Kilogramm).
  final Money priceNet;

  /// Umsatzsteuersatz.
  final VatRate vatRate;

  /// Nettobetrag der Position.
  Money get netTotal => quantity.valueAt(priceNet);
}

/// Summen einer Rechnung, USt getrennt nach Satz.
final class InvoiceTotals {
  /// Erzeugt die Summen.
  const InvoiceTotals({
    required this.net,
    required this.net7,
    required this.net19,
    required this.vat7,
    required this.vat19,
  });

  /// Nettosumme aller Positionen.
  final Money net;

  /// Netto der Positionen mit 7 %.
  final Money net7;

  /// Netto der Positionen mit 19 %.
  final Money net19;

  /// USt auf [net7].
  final Money vat7;

  /// USt auf [net19].
  final Money vat19;

  /// Gesamtbetrag brutto.
  Money get gross => net + vat7 + vat19;
}

/// Rechnet Rechnungssummen für die Live-Anzeige (maßgeblich: `_recalc_invoice`).
final class InvoiceCalculator {
  /// Erzeugt den Rechner.
  const InvoiceCalculator();

  /// Summiert die Positionen; bei Kleinunternehmern entfällt die USt.
  InvoiceTotals calculate(
    List<InvoiceLine> lines, {
    required bool isSmallBusiness,
  }) {
    final net7 = _netFor(lines, VatRate.reduced);
    final net19 = _netFor(lines, VatRate.standard);
    final net0 = _netFor(lines, VatRate.zero);
    return InvoiceTotals(
      net: net0 + net7 + net19,
      net7: net7,
      net19: net19,
      vat7: isSmallBusiness
          ? Money.zero
          : net7.percent(VatRate.reduced.percent),
      vat19: isSmallBusiness
          ? Money.zero
          : net19.percent(VatRate.standard.percent),
    );
  }

  Money _netFor(List<InvoiceLine> lines, VatRate rate) => lines
      .where((line) => line.vatRate == rate)
      .fold(Money.zero, (sum, line) => sum + line.netTotal);
}
