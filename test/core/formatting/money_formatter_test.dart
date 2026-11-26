import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/value_objects/money.dart';

void main() {
  const nbsp = '\u00A0';

  test('1250 Cent → „12,50 €“', () {
    expect(MoneyFormatter.format(const Money(1250)), '12,50$nbsp€');
  });

  test('Tausenderpunkt: 123456 Cent → „1.234,56 €“', () {
    expect(MoneyFormatter.format(const Money(123456)), '1.234,56$nbsp€');
  });

  test('Millionen: 123456789 Cent → „1.234.567,89 €“', () {
    expect(MoneyFormatter.format(const Money(123456789)), '1.234.567,89$nbsp€');
  });

  test('0 und 5 Cent behalten zwei Nachkommastellen', () {
    expect(MoneyFormatter.format(Money.zero), '0,00$nbsp€');
    expect(MoneyFormatter.format(const Money(5)), '0,05$nbsp€');
  });

  test('negativ: −800 Cent → „−8,00 €“', () {
    expect(MoneyFormatter.format(const Money(-800)), '−8,00$nbsp€');
  });

  test('formatSigned zeigt + bei Überschuss', () {
    expect(MoneyFormatter.formatSigned(const Money(200)), '+2,00$nbsp€');
    expect(MoneyFormatter.formatSigned(const Money(-800)), '−8,00$nbsp€');
    expect(MoneyFormatter.formatSigned(Money.zero), '0,00$nbsp€');
  });

  test('Ausgabe lässt sich wieder einlesen', () {
    const money = Money(123456);
    expect(Money.tryParse(MoneyFormatter.formatPlain(money)), money);
  });
}
