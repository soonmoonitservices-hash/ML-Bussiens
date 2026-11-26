import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

void main() {
  test('rechnet 13 Kartons × 4 + 3 Gläser zu 55 Gläsern', () {
    final quantity = Quantity.fromCartons(
      cartons: 13,
      loosePieces: 3,
      unitsPerCarton: 4,
      unit: ProductUnit.jar,
    );

    expect(quantity.base, 55);
  });

  test('zerlegt 55 Gläser in 13 Kartons + 3 Gläser', () {
    const quantity = Quantity(55, ProductUnit.jar);

    final split = quantity.splitIntoCartons(4);

    expect(split.cartons, 13);
    expect(split.loosePieces, 3);
  });

  test('liest „12,5“ kg als 12500 g', () {
    expect(Quantity.tryParseKilograms('12,5')?.base, 12500);
  });

  test('liest „600“ kg als 600000 g', () {
    expect(Quantity.tryParseKilograms('600')?.base, 600000);
  });

  test('lehnt mehr als drei Nachkommastellen ab', () {
    expect(Quantity.tryParseKilograms('1,2345'), isNull);
  });

  test('bewertet Gläser mit Stückpreis', () {
    const quantity = Quantity(48, ProductUnit.jar);

    expect(quantity.valueAt(const Money(450)).cents, 21600);
  });

  test('bewertet Gramm mit Kilopreis und rundet auf Cent', () {
    const quantity = Quantity(12500, ProductUnit.kg);

    expect(quantity.valueAt(const Money(900)).cents, 11250);
  });
}
