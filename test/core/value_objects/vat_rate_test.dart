import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

void main() {
  test('fromPercent findet die Sätze 0, 7 und 19', () {
    expect(VatRate.fromPercent(0), VatRate.zero);
    expect(VatRate.fromPercent(7), VatRate.reduced);
    expect(VatRate.fromPercent(19), VatRate.standard);
  });

  test('fromPercent wirft bei unbekanntem Satz', () {
    expect(() => VatRate.fromPercent(16), throwsStateError);
  });

  test('Brutto aus Netto: 100,00 € → 107,00 € (7 %) und 119,00 € (19 %)', () {
    expect(
      VatRate.reduced.grossFromNet(const Money(10000)),
      const Money(10700),
    );
    expect(
      VatRate.standard.grossFromNet(const Money(10000)),
      const Money(11900),
    );
    expect(VatRate.zero.grossFromNet(const Money(10000)), const Money(10000));
  });

  test('USt wird kaufmännisch gerundet: 0,50 € × 19 % = 0,095 → 0,10 €', () {
    expect(VatRate.standard.grossFromNet(const Money(50)), const Money(60));
  });

  test('Netto aus Brutto: 119,00 € → 100,00 €', () {
    expect(
      VatRate.standard.netFromGross(const Money(11900)),
      const Money(10000),
    );
    expect(
      VatRate.reduced.netFromGross(const Money(10700)),
      const Money(10000),
    );
  });

  test('Netto + USt = Brutto, Cent-genau', () {
    for (final rate in VatRate.values) {
      for (var gross = 0; gross <= 5000; gross++) {
        final net = rate.netFromGross(Money(gross));
        final vat = Money(gross) - net;
        expect(net + vat, Money(gross));
      }
    }
  });
}
