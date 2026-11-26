import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/load_calculator.dart';

void main() {
  const calculator = LoadCalculator();

  test('berechnet Einkaufswert, Verkaufswert und erwarteten Gewinn', () {
    final summary = calculator.summarize(const [
      LoadLine(
        quantity: Quantity(55, ProductUnit.jar),
        buyPrice: Money(300),
        sellPrice: Money(450),
      ),
      LoadLine(
        quantity: Quantity(12500, ProductUnit.kg),
        buyPrice: Money(600),
        sellPrice: Money(900),
      ),
    ]);

    expect(summary.costValue.cents, 55 * 300 + 7500);
    expect(summary.sellValue.cents, 55 * 450 + 11250);
    expect(
      summary.expectedProfit.cents,
      summary.sellValue.cents - summary.costValue.cents,
    );
  });
}
