import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

void main() {
  test('„55 Gläser“, „1 Glas“, „12,5 kg“, „12 kg“', () {
    expect(
      QuantityFormatter.format(const Quantity(55, ProductUnit.jar)),
      '55 Gläser',
    );
    expect(
      QuantityFormatter.format(const Quantity(1, ProductUnit.jar)),
      '1 Glas',
    );
    expect(
      QuantityFormatter.format(const Quantity(12500, ProductUnit.kg)),
      '12,5 kg',
    );
    expect(
      QuantityFormatter.format(const Quantity(12000, ProductUnit.kg)),
      '12 kg',
    );
    expect(
      QuantityFormatter.format(const Quantity(250, ProductUnit.kg)),
      '0,25 kg',
    );
  });

  test('Karton-Zerlegung: 55 Gläser → 13 Kartons + 3 Gläser', () {
    expect(
      QuantityFormatter.cartonBreakdown(const Quantity(55, ProductUnit.jar), 4),
      '13 Kartons + 3 Gläser',
    );
    expect(
      QuantityFormatter.cartonBreakdown(
        const Quantity(48, ProductUnit.piece),
        12,
      ),
      '4 Kartons',
    );
    expect(
      QuantityFormatter.cartonBreakdown(const Quantity(3, ProductUnit.jar), 4),
      '3 Gläser',
    );
    expect(
      QuantityFormatter.cartonBreakdown(
        const Quantity(5, ProductUnit.jar),
        null,
      ),
      isNull,
    );
  });

  test('Datum und Uhrzeit deutsch', () {
    final value = DateTime(2026, 11, 6, 9, 5);
    expect(DateFormatter.date(value), '06.11.2026');
    expect(DateFormatter.dateTime(value), '06.11.2026, 09:05 Uhr');
    expect(DateFormatter.monthYear(2026, 11), 'November 2026');
    expect(DateFormatter.iso(value), '2026-11-06');
  });
}
