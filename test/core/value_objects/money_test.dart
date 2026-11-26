import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

void main() {
  group('Money.tryParse', () {
    test('liest „12,50“ als 1250 Cent', () {
      expect(Money.tryParse('12,50'), const Money(1250));
    });

    test('liest „12.50“ mit Punkt als 1250 Cent', () {
      expect(Money.tryParse('12.50'), const Money(1250));
    });

    test('liest „1.234,56“ mit Tausenderpunkt', () {
      expect(Money.tryParse('1.234,56'), const Money(123456));
    });

    test('liest „12,5“ als 1250 Cent', () {
      expect(Money.tryParse('12,5'), const Money(1250));
    });

    test('lehnt mehr als zwei Nachkommastellen ab', () {
      expect(Money.tryParse('12,505'), isNull);
    });

    test('lehnt Text ab', () {
      expect(Money.tryParse('abc'), isNull);
    });
  });

  group('Rechnen', () {
    test('addiert, subtrahiert und multipliziert ohne Rundungsfehler', () {
      const a = Money(10);
      const b = Money(20);

      expect((a + b).cents, 30);
      expect((a - b).cents, -10);
      expect(const Money(450).times(48).cents, 21600);
    });

    test('rundet Prozent kaufmännisch (0,5 Cent wird aufgerundet)', () {
      expect(const Money(50).percent(7).cents, 4); // 3,5 -> 4
      expect(const Money(-50).percent(7).cents, -4);
    });
  });

  group('VatRate', () {
    test('rechnet Brutto aus Netto', () {
      expect(VatRate.reduced.grossFromNet(const Money(10000)).cents, 10700);
    });

    test('rechnet Netto aus Brutto', () {
      expect(VatRate.standard.netFromGross(const Money(11900)).cents, 10000);
    });
  });
}
