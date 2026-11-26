import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/tours/domain/settlement_calculator.dart';

void main() {
  const calculator = SettlementCalculator();

  // 48 Gläser × 4,50 € = 216,00 €; Käse 100 kg × 6,87 € = 687,00 €; zusammen 903,00 €.
  const lines = [
    SettlementLine(
      loaded: Quantity(55, ProductUnit.jar),
      returned: Quantity(7, ProductUnit.jar),
      buyPrice: Money(300),
      sellPrice: Money(450),
      vatRate: VatRate.reduced,
    ),
    SettlementLine(
      loaded: Quantity(100000, ProductUnit.kg),
      returned: Quantity.zero(ProductUnit.kg),
      buyPrice: Money(600),
      sellPrice: Money(687),
      vatRate: VatRate.reduced,
    ),
  ];
  const expenses = [
    SettlementExpense(gross: Money(1500)),
    SettlementExpense(gross: Money(2000)),
  ];

  Settlement settle(int cashCents, {bool includesVat = false}) =>
      calculator.calculate(
        lines: lines,
        expenses: expenses,
        cashReceived: Money(cashCents),
        cashIncludesVat: includesVat,
      );

  test('verkauft 48 Gläser, wenn 55 geladen und 7 zurückgebracht werden', () {
    expect(lines.first.sold.base, 48);
  });

  test('berechnet Soll-Bargeld 868,00 € aus 903,00 € Umsatz minus 35,00 € Ausgaben', () {
    final result = settle(86800);

    expect(result.revenueNet.cents, 90300);
    expect(result.expensesGross.cents, 3500);
    expect(result.expectedCash.cents, 86800);
  });

  test(
    'gibt Fehlbetrag −8,00 € zurück, wenn 860 € statt 868 € übergeben werden',
    () {
      expect(settle(86000).difference.cents, -800);
    },
  );

  test('gibt Überschuss +2,00 € zurück, wenn 870 € übergeben werden', () {
    expect(settle(87000).difference.cents, 200);
  });

  test('meldet „Kasse stimmt“ bei 868,00 €', () {
    expect(settle(86800).isBalanced, isTrue);
  });

  test(
    'Entfernte Produkte aus einem Karton senken Umsatz und Wareneinsatz',
    () {
      // 2 Kartons à 20,00 € (Einkauf 10,00 €); 1 Glas zurück, 1 Glas geschenkt (je 4,50 € / 3,00 €).
      final result = calculator.calculate(
        lines: const [
          SettlementLine(
            loaded: Quantity(2, ProductUnit.carton),
            returned: Quantity.zero(ProductUnit.carton),
            buyPrice: Money(1000),
            sellPrice: Money(2000),
            vatRate: VatRate.reduced,
            removedRevenue: Money(900),
            removedCost: Money(300),
          ),
        ],
        expenses: const [],
        cashReceived: const Money(3100),
        cashIncludesVat: false,
      );
      expect(result.revenueNet, const Money(3100));
      expect(result.cost, const Money(1700));
      expect(result.isBalanced, isTrue);
    },
  );

  test(
    'Bargeld geht in den Gewinn ein: Mehr- und Wenigerbetrag zählen dazu',
    () {
      final balanced = settle(86800).profit;
      expect(settle(87000).profit, balanced + const Money(200)); // +2,00 € Mehr
      expect(
        settle(86000).profit,
        balanced - const Money(800),
      ); // −8,00 € Weniger
    },
  );

  test('berechnet Tourgewinn als Umsatz − Wareneinsatz − Ausgaben', () {
    final result = settle(86800);

    // Wareneinsatz: 48 × 3,00 € + 100 kg × 6,00 € = 744,00 €
    expect(result.cost.cents, 74400);
    expect(result.profit.cents, 90300 - 74400 - 3500);
  });

  test('erwartet bei cashIncludesVat den Bruttoumsatz', () {
    final result = settle(0, includesVat: true);

    expect(result.expectedCash.cents, result.revenueGross.cents - 3500);
  });

  test('wirft einen Fehler, wenn mehr zurückkommt als geladen wurde', () {
    expect(
      () => calculator.calculate(
        lines: const [
          SettlementLine(
            loaded: Quantity(5, ProductUnit.jar),
            returned: Quantity(6, ProductUnit.jar),
            buyPrice: Money(300),
            sellPrice: Money(450),
            vatRate: VatRate.reduced,
          ),
        ],
        expenses: const [],
        cashReceived: Money.zero,
        cashIncludesVat: false,
      ),
      throwsA(isA<ReturnExceedsLoadException>()),
    );
  });

  group('Geschenkte Produkte', () {
    // 55 Gläser geladen, 7 zurück, 5 geschenkt: 43 bezahlt (193,50 €),
    // Wareneinsatz zählt 48 Gläser (144,00 €).
    const giftLines = [
      SettlementLine(
        loaded: Quantity(55, ProductUnit.jar),
        returned: Quantity(7, ProductUnit.jar),
        gift: Quantity(5, ProductUnit.jar),
        buyPrice: Money(300),
        sellPrice: Money(450),
        vatRate: VatRate.reduced,
      ),
    ];

    Settlement giftSettle() => calculator.calculate(
      lines: giftLines,
      expenses: const [],
      cashReceived: const Money(19350),
      cashIncludesVat: false,
    );

    test('Umsatz nur für bezahlte Gläser, Soll-Bargeld sinkt', () {
      expect(giftSettle().revenueNet, const Money(19350));
      expect(giftSettle().expectedCash, const Money(19350));
      expect(giftSettle().isBalanced, isTrue);
    });

    test('Wareneinsatz zählt Geschenke mit, Gewinn sinkt', () {
      expect(giftSettle().cost, const Money(14400));
      expect(giftSettle().profit, const Money(19350 - 14400));
    });

    test('zurück plus geschenkt über der Ladung wirft einen Fehler', () {
      expect(
        () => calculator.calculate(
          lines: const [
            SettlementLine(
              loaded: Quantity(55, ProductUnit.jar),
              returned: Quantity(30, ProductUnit.jar),
              gift: Quantity(26, ProductUnit.jar),
              buyPrice: Money(300),
              sellPrice: Money(450),
              vatRate: VatRate.reduced,
            ),
          ],
          expenses: const [],
          cashReceived: Money.zero,
          cashIncludesVat: false,
        ),
        throwsA(isA<ReturnExceedsLoadException>()),
      );
    });
  });
}
