import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';

void main() {
  // Oliven: 55 Gläser geladen, 7 zurück, 5 geschenkt → 43 bezahlt zu 4,50 €.
  // Karton: 2 geladen zu 20,00 €; daraus 1 Glas zurück und 1 geschenkt (je 4,50 €).
  const inputs = [
    GoodsInput(
      name: 'Grüne Oliven',
      loaded: Quantity(55, ProductUnit.jar),
      returned: Quantity(7, ProductUnit.jar),
      gift: Quantity(5, ProductUnit.jar),
      sellPrice: Money(450),
    ),
    GoodsInput(
      name: 'Probierkarton',
      loaded: Quantity(2, ProductUnit.carton),
      returned: Quantity.zero(ProductUnit.carton),
      gift: Quantity.zero(ProductUnit.carton),
      sellPrice: Money(2000),
      removals: [
        GoodsRemovalInput(
          label: 'Oliven (aus Probierkarton)',
          returned: Quantity(1, ProductUnit.jar),
          gift: Quantity(1, ProductUnit.jar),
          sellPrice: Money(450),
        ),
      ],
    ),
  ];

  test('Verkaufte Ware: bezahlte Menge mit Einzel- und Gesamtpreis', () {
    final lines = GoodsLists.sold(inputs);
    expect(lines.first.name, 'Grüne Oliven');
    expect(lines.first.quantity.base, 43);
    expect(lines.first.unitPrice, const Money(450));
    expect(lines.first.total, const Money(19350));
  });

  test('Verkaufte Ware: aus Kartons entfernte Produkte sind ein Abzug', () {
    final lines = GoodsLists.sold(inputs);
    expect(lines.length, 3);
    expect(lines[1].name, 'Probierkarton');
    expect(lines[1].total, const Money(4000));
    expect(lines[2].name, 'Oliven (aus Probierkarton)');
    expect(lines[2].quantity.base, 2);
    expect(lines[2].total, const Money(-900));
    // 193,50 + 40,00 − 9,00 = 224,50 €
    expect(GoodsLists.total(lines), const Money(22450));
  });

  test('Zurückgeholte Ware: zurückgebrachte Menge mit Preisen', () {
    final lines = GoodsLists.returned(inputs);
    expect(lines.length, 2);
    expect(lines[0].name, 'Grüne Oliven');
    expect(lines[0].quantity.base, 7);
    expect(lines[0].total, const Money(3150));
    expect(lines[1].name, 'Oliven (aus Probierkarton)');
    expect(lines[1].quantity.base, 1);
    expect(lines[1].total, const Money(450));
    expect(GoodsLists.total(lines), const Money(3600));
  });

  test('Ohne Rückgabe ist die Liste der zurückgeholten Ware leer', () {
    final lines = GoodsLists.returned(const [
      GoodsInput(
        name: 'Grüne Oliven',
        loaded: Quantity(10, ProductUnit.jar),
        returned: Quantity.zero(ProductUnit.jar),
        gift: Quantity.zero(ProductUnit.jar),
        sellPrice: Money(450),
      ),
    ]);
    expect(lines, isEmpty);
  });
}
