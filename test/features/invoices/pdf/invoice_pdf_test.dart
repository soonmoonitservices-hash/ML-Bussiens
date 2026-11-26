import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/invoices/pdf/invoice_pdf.dart';

import '../../../helpers/pdf_test_data.dart';

InvoicePdfData data(
  int count, {
  String? number = 'RE-2026-001',
  String? cancels,
  int sign = 1,
  bool small = false,
}) => InvoicePdfData(
  company: testCompany(),
  recipient: testRecipient,
  number: number,
  date: DateTime(2026, 11, 16),
  serviceDate: DateTime(2026, 11, 15),
  dueDate: DateTime(2026, 11, 30),
  deliveryNoteNumber: 'LS-2026-001',
  cancelsInvoiceNumber: cancels,
  isSmallBusiness: small,
  note: 'Bitte Rechnungsnummer angeben.',
  lines: [
    for (var i = 0; i < count; i++)
      InvoicePdfLine(
        name: 'Artikel $i mit einem recht langen Namen zum Umbrechen',
        quantity: Quantity(sign * 10, ProductUnit.piece),
        priceNet: const Money(1250),
        vatRate: i.isEven ? VatRate.reduced : VatRate.standard,
        lineNet: Money(sign * 12500),
      ),
  ],
  net: Money(sign * 12500 * count),
  vat7: Money(sign * 875 * ((count + 1) ~/ 2)),
  vat19: Money(sign * 2375 * (count ~/ 2)),
  gross: Money(sign * 15750 * count),
);

void main() {
  final fonts = loadTestFonts();

  test('erzeugt ein PDF mit 1 Position', () async {
    final pdf = await InvoicePdf.generate(data(1), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), 1);
  });

  test('erzeugt ein mehrseitiges PDF mit 60 Positionen', () async {
    final pdf = await InvoicePdf.generate(data(60), fonts);
    expect(isPdf(pdf), isTrue);
    expect(pageCount(pdf), greaterThan(1));
  });

  test('erzeugt einen Entwurf ohne Nummer', () async {
    final pdf = await InvoicePdf.generate(data(2, number: null), fonts);
    expect(isPdf(pdf), isTrue);
  });

  test('erzeugt eine Rechnung für Kleinunternehmer', () async {
    final pdf = await InvoicePdf.generate(data(2, small: true), fonts);
    expect(isPdf(pdf), isTrue);
  });

  test('erzeugt eine Stornorechnung mit negativen Beträgen', () async {
    final pdf = await InvoicePdf.generate(
      data(2, number: 'RE-2026-005', cancels: 'RE-2026-001', sign: -1),
      fonts,
    );
    expect(isPdf(pdf), isTrue);
  });
}
