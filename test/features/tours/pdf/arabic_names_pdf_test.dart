import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/pdf/tour_summary_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

void main() {
  final fonts = loadTestFonts();
  test('erzeugt ein PDF mit arabischem Produktnamen (kg)', () async {
    final pdf = await TourSummaryPdf.generate(
      TourSummaryPdfData(
        company: testCompany(),
        tourNumber: 'T-2026-005',
        driverName: 'حمودة',
        date: DateTime(2026, 11, 16),
        lines: const [
          TourPdfLine(
            name: 'جبنة بلدي',
            loaded: Quantity(650000, ProductUnit.kg),
            returned: Quantity(25000, ProductUnit.kg),
            sellPrice: Money(600),
            revenue: Money(390000),
          ),
        ],
        expenses: const [],
        revenue: const Money(455500),
        expensesGross: const Money(32000),
        expectedCash: const Money(423500),
        cashReceived: const Money(423500),
        difference: Money.zero,
        cost: const Money(1),
        profit: const Money(1),
      ),
      fonts,
    );
    expect(isPdf(pdf), isTrue);
  });
}
