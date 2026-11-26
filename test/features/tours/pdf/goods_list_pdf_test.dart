import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';
import 'package:warenbestand/features/tours/pdf/goods_list_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

GoodsListPdfData data(int count, GoodsListKind kind) {
  final lines = [
    for (var i = 0; i < count; i++)
      const GoodsLine(
        name: 'Grüne Oliven',
        quantity: Quantity(48, ProductUnit.jar),
        unitPrice: Money(450),
        total: Money(21600),
      ),
  ];
  return GoodsListPdfData(
    company: testCompany(),
    kind: kind,
    tourNumber: 'T-2026-012',
    driverName: 'Mehmet Yilmaz',
    date: DateTime(2026, 11, 16),
    lines: lines,
    total: GoodsLists.total(lines),
  );
}

void main() {
  final fonts = loadTestFonts();

  test('Verkaufte Ware: 1 Position', () async {
    final pdf = await GoodsListPdf.generate(data(1, GoodsListKind.sold), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });

  test('Zurückgeholte Ware: 60 Positionen über mehrere Seiten', () async {
    final pdf = await GoodsListPdf.generate(
      data(60, GoodsListKind.returned),
      fonts,
    );
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(1));
  });
}
