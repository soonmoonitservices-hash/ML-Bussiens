import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/pdf/tour_summary_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

TourSummaryPdfData data(int count, {Money difference = const Money(-800)}) =>
    TourSummaryPdfData(
      company: testCompany(),
      tourNumber: 'T-2026-012',
      driverName: 'Mehmet Yilmaz',
      date: DateTime(2026, 11, 16),
      startedAt: DateTime(2026, 11, 16, 6),
      closedAt: DateTime(2026, 11, 16, 18, 30),
      lines: [
        for (var i = 0; i < count; i++)
          const TourPdfLine(
            name: 'Grüne Oliven',
            loaded: Quantity(55, ProductUnit.jar),
            returned: Quantity(7, ProductUnit.jar),
            sellPrice: Money(450),
            revenue: Money(21600),
          ),
      ],
      expenses: const [
        TourPdfExpense(title: 'Diesel', gross: Money(30000)),
        TourPdfExpense(title: 'Essen', gross: Money(2000)),
      ],
      revenue: const Money(90300),
      expensesGross: const Money(3500),
      expectedCash: const Money(86800),
      cashReceived: Money(86800 + difference.cents),
      difference: difference,
      differenceReason: difference.isZero ? null : 'Wechselgeld fehlte',
      cost: const Money(51760),
      profit: const Money(35040),
    );

void main() {
  final fonts = loadTestFonts();

  test('erzeugt ein PDF mit 1 Position', () async {
    final pdf = await TourSummaryPdf.generate(data(1), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });

  test('erzeugt ein mehrseitiges PDF mit 60 Positionen', () async {
    final pdf = await TourSummaryPdf.generate(data(60), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(1));
  });

  test('erzeugt PDFs für Überschuss und passende Kasse', () async {
    final surplus = await TourSummaryPdf.generate(
      data(1, difference: const Money(200)),
      fonts,
    );
    final balanced = await TourSummaryPdf.generate(
      data(1, difference: Money.zero),
      fonts,
    );
    expect(isPdf(surplus), isTrue);
    expect(isPdf(balanced), isTrue);
  });
}
