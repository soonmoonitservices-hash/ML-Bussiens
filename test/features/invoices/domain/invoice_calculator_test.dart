import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/invoices/domain/invoice_calculator.dart';

void main() {
  const calculator = InvoiceCalculator();

  InvoiceLine line(int quantity, int priceCents, VatRate rate) => InvoiceLine(
    quantity: Quantity(quantity, ProductUnit.piece),
    priceNet: Money(priceCents),
    vatRate: rate,
  );

  test('berechnet nur 7 %', () {
    final totals = calculator.calculate([
      line(10, 1000, VatRate.reduced),
    ], isSmallBusiness: false);

    expect(totals.net.cents, 10000);
    expect(totals.vat7.cents, 700);
    expect(totals.vat19.cents, 0);
    expect(totals.gross.cents, 10700);
  });

  test('berechnet nur 19 %', () {
    final totals = calculator.calculate([
      line(10, 1000, VatRate.standard),
    ], isSmallBusiness: false);

    expect(totals.vat19.cents, 1900);
    expect(totals.gross.cents, 11900);
  });

  test('weist 7 % und 19 % getrennt aus', () {
    final totals = calculator.calculate([
      line(10, 1000, VatRate.reduced),
      line(5, 2000, VatRate.standard),
    ], isSmallBusiness: false);

    expect(totals.net7.cents, 10000);
    expect(totals.net19.cents, 10000);
    expect(totals.vat7.cents, 700);
    expect(totals.vat19.cents, 1900);
    expect(totals.gross.cents, 20000 + 700 + 1900);
  });

  test('rundet USt kaufmännisch auf Cent', () {
    final totals = calculator.calculate([
      line(1, 50, VatRate.reduced),
    ], isSmallBusiness: false);

    expect(totals.vat7.cents, 4);
    expect(totals.gross.cents, totals.net.cents + totals.vat7.cents);
  });

  test('weist bei Kleinunternehmern keine USt aus', () {
    final totals = calculator.calculate([
      line(10, 1000, VatRate.reduced),
    ], isSmallBusiness: true);

    expect(totals.vat7.cents, 0);
    expect(totals.gross.cents, 10000);
  });
}
