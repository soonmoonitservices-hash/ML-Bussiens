import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/reports/pdf/report_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

ReportPdfData data(int count) => ReportPdfData(
  company: testCompany(),
  from: DateTime(2026, 11),
  to: DateTime(2026, 11, 30),
  kpis: const [
    ReportPdfKpi(label: 'Umsatz', value: Money(903000), changePercent: 12),
    ReportPdfKpi(
      label: 'Wareneinsatz',
      value: Money(517600),
      changePercent: -3,
    ),
    ReportPdfKpi(label: 'Ausgaben', value: Money(35000)),
    ReportPdfKpi(label: 'Gewinn', value: Money(350400), changePercent: 0),
  ],
  topProducts: [
    for (var i = 0; i < count; i++)
      ReportPdfProduct(
        name: 'Produkt $i',
        sold: const Quantity(480, ProductUnit.jar),
        revenue: Money(216000 + i),
      ),
  ],
  expensesByCategory: [
    for (var i = 0; i < count; i++)
      ReportPdfCategory(
        category: 'Kategorie $i',
        amount: Money(1000 * (i + 1)),
      ),
  ],
  drivers: [
    for (var i = 0; i < count; i++)
      ReportPdfDriver(
        name: 'Fahrer $i',
        tours: 12,
        revenue: const Money(903000),
        averagePerTour: const Money(75250),
        returnRatePercent: 14,
        differenceTotal: const Money(-800),
      ),
  ],
);

void main() {
  final fonts = loadTestFonts();

  test('erzeugt ein PDF mit 1 Position', () async {
    final pdf = await ReportPdf.generate(data(1), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });

  test('erzeugt ein mehrseitiges PDF mit 60 Positionen', () async {
    final pdf = await ReportPdf.generate(data(60), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(1));
  });

  test('erzeugt ein PDF ohne Daten', () async {
    final pdf = await ReportPdf.generate(data(0), fonts);
    expect(isPdf(pdf), isTrue);
  });
}
