import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

Money _money(Object? value) => Money((value as num?)?.toInt() ?? 0);

/// Kennzahlen eines Zeitraums (Funktion `report_kpis`). Umsatz = abgeschlossene
/// Touren plus festgeschriebene Rechnungen ohne Tour, Storno und Original
/// heben sich auf.
final class ReportKpis {
  const ReportKpis({
    required this.revenue,
    required this.cost,
    required this.expenses,
    required this.profit,
    required this.tourCount,
    required this.invoiceCount,
  });

  factory ReportKpis.fromJson(Map<String, dynamic> json) => ReportKpis(
    revenue: _money(json['revenue_net_cents']),
    cost: _money(json['cost_cents']),
    expenses: _money(json['expenses_net_cents']),
    profit: _money(json['profit_cents']),
    tourCount: (json['tour_count'] as num?)?.toInt() ?? 0,
    invoiceCount: (json['invoice_count'] as num?)?.toInt() ?? 0,
  );

  final Money revenue;
  final Money cost;
  final Money expenses;
  final Money profit;
  final int tourCount;
  final int invoiceCount;
}

/// Ein Punkt der Zeitreihe (Umsatz und Ausgaben je Tag, Woche oder Monat).
final class ReportPoint {
  const ReportPoint({
    required this.start,
    required this.revenue,
    required this.expenses,
    required this.profit,
  });

  factory ReportPoint.fromJson(Map<String, dynamic> json) => ReportPoint(
    start: DateTime.parse(json['period_start'] as String),
    revenue: _money(json['revenue_net_cents']),
    expenses: _money(json['expenses_net_cents']),
    profit: _money(json['profit_cents']),
  );

  final DateTime start;
  final Money revenue;
  final Money expenses;
  final Money profit;
}

/// Verkaufte Menge und Umsatz eines Produkts.
final class ReportProduct {
  const ReportProduct({
    required this.name,
    required this.sold,
    required this.revenue,
  });

  factory ReportProduct.fromJson(Map<String, dynamic> json) {
    final unit = ProductUnit.fromDb(json['unit'] as String);
    return ReportProduct(
      name: json['product_name'] as String,
      sold: Quantity((json['sold_qty'] as num).toInt(), unit),
      revenue: _money(json['revenue_net_cents']),
    );
  }

  final String name;
  final Quantity sold;
  final Money revenue;
}

/// Ausgaben einer Kategorie.
final class ReportCategory {
  const ReportCategory({required this.category, required this.net});

  factory ReportCategory.fromJson(Map<String, dynamic> json) => ReportCategory(
    category: json['category'] as String,
    net: _money(json['net_cents']),
  );

  final String category;
  final Money net;
}

/// Zeile der Fahrerstatistik.
final class DriverStat {
  const DriverStat({
    required this.name,
    required this.tours,
    required this.revenue,
    required this.averagePerTour,
    required this.returnRatePercent,
    required this.differenceSum,
    required this.shortageSum,
  });

  factory DriverStat.fromJson(Map<String, dynamic> json) => DriverStat(
    name: json['driver_name'] as String,
    tours: (json['tour_count'] as num).toInt(),
    revenue: _money(json['revenue_net_cents']),
    averagePerTour: _money(json['avg_revenue_per_tour_cents']),
    // Die Datenbank liefert die Quote nach Wert als Anteil (0,1234 = 12,34 %).
    returnRatePercent: ((json['return_rate'] as num) * 100).round(),
    differenceSum: _money(json['difference_sum_cents']),
    shortageSum: _money(json['shortage_sum_cents']),
  );

  final String name;
  final int tours;
  final Money revenue;
  final Money averagePerTour;
  final int returnRatePercent;

  /// Summe aller Kassendifferenzen (negativ = Fehlbetrag).
  final Money differenceSum;

  /// Summe der Fehlbeträge.
  final Money shortageSum;
}

/// Alles, was der Auswertungs-Screen und der Bericht zeigen.
final class ReportData {
  const ReportData({
    required this.kpis,
    required this.previous,
    required this.points,
    required this.products,
    required this.categories,
    required this.drivers,
  });

  final ReportKpis kpis;
  final ReportKpis previous;
  final List<ReportPoint> points;
  final List<ReportProduct> products;
  final List<ReportCategory> categories;
  final List<DriverStat> drivers;
}
