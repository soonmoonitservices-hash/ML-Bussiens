import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/receipts/pdf/expenses_month_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

ExpensesMonthPdfData data(int count, {bool cover = true}) =>
    ExpensesMonthPdfData(
      company: testCompany(),
      year: 2026,
      month: 11,
      includeCover: cover,
      items: [
        for (var i = 0; i < count; i++)
          ExpensePdfItem(
            date: DateTime(2026, 11, 1 + i % 28),
            title: 'Diesel Tankstelle $i',
            category: 'Fahrzeug & Kraftstoff',
            vatRate: VatRate.standard,
            net: const Money(8403),
            gross: const Money(10000),
            image: i.isEven ? tinyPng : null,
          ),
      ],
      net: Money(8403 * count),
      vat: Money(1597 * count),
      gross: Money(10000 * count),
      byCategory: [
        ExpenseCategoryTotal(
          category: 'Fahrzeug & Kraftstoff',
          gross: Money(10000 * count),
        ),
      ],
    );

void main() {
  final fonts = loadTestFonts();

  test('erzeugt ein PDF mit 1 Beleg (Deckblatt + Belegseite)', () async {
    final pdf = await ExpensesMonthPdf.generate(data(1), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 2);
  });

  test('erzeugt ein mehrseitiges PDF mit 60 Belegen', () async {
    final pdf = await ExpensesMonthPdf.generate(data(60), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(60));
  });

  test('einzelner Beleg ohne Deckblatt hat eine Seite', () async {
    final pdf = await ExpensesMonthPdf.generate(data(1, cover: false), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });
}
