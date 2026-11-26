import 'package:warenbestand/core/value_objects/money.dart';

/// Verkaufseinheit eines Produkts (wie `product_unit` in der Datenbank).
enum ProductUnit {
  /// Karton.
  carton('carton'),

  /// Stück.
  piece('piece'),

  /// Glas.
  jar('jar'),

  /// Kilogramm, intern in Gramm.
  kg('kg');

  const ProductUnit(this.dbValue);

  /// Wert in der Datenbank.
  final String dbValue;

  /// Ob die Menge in Gramm gespeichert wird.
  bool get isWeight => this == ProductUnit.kg;

  /// Findet die Einheit zum Datenbankwert.
  static ProductUnit fromDb(String value) =>
      ProductUnit.values.firstWhere((unit) => unit.dbValue == value);
}

/// Menge in Basiseinheit: Stück/Gläser als ganze Zahl, Kilogramm in Gramm.
final class Quantity {
  /// Erzeugt eine Menge aus der Basiseinheit (Stück oder Gramm).
  const Quantity(this.base, this.unit);

  /// Menge 0 in der angegebenen Einheit.
  const Quantity.zero(this.unit) : base = 0;

  /// Kartons × Inhalt pro Karton + einzelne Stück (z. B. 13 × 4 + 3 = 55).
  factory Quantity.fromCartons({
    required int cartons,
    required int loosePieces,
    required int unitsPerCarton,
    required ProductUnit unit,
  }) => Quantity(cartons * unitsPerCarton + loosePieces, unit);

  /// Menge in Basiseinheit (Stück/Gläser oder Gramm).
  final int base;

  /// Einheit des Produkts.
  final ProductUnit unit;

  /// Liest Kilogramm wie „12,5“ in Gramm. Maximal drei Nachkommastellen.
  static Quantity? tryParseKilograms(String input) {
    final match = RegExp(r'^(\d+)(?:[.,](\d{1,3}))?$').firstMatch(input.trim());
    if (match == null) {
      return null;
    }
    final fraction = (match.group(2) ?? '').padRight(3, '0');
    final grams = int.parse(match.group(1)!) * 1000 + int.parse(fraction);
    return Quantity(grams, ProductUnit.kg);
  }

  /// Zerlegt in volle Kartons und Rest (nur sinnvoll bei Karton-Produkten).
  ({int cartons, int loosePieces}) splitIntoCartons(int unitsPerCarton) =>
      (cartons: base ~/ unitsPerCarton, loosePieces: base % unitsPerCarton);

  /// Summe zweier Mengen derselben Einheit.
  Quantity operator +(Quantity other) => Quantity(base + other.base, unit);

  /// Differenz zweier Mengen derselben Einheit.
  Quantity operator -(Quantity other) => Quantity(base - other.base, unit);

  /// Ob die Menge größer als die andere ist.
  bool operator >(Quantity other) => base > other.base;

  /// Wert zum Netto-Einzelpreis (pro Basiseinheit, bei kg pro Kilogramm),
  /// gerundet wie `line_value_cents` in der Datenbank.
  Money valueAt(Money unitPrice) => unit.isWeight
      ? Money(roundHalfAwayFromZero(base * unitPrice.cents, 1000))
      : Money(base * unitPrice.cents);

  @override
  bool operator ==(Object other) =>
      other is Quantity && other.base == base && other.unit == unit;

  @override
  int get hashCode => Object.hash(base, unit);

  @override
  String toString() => 'Quantity($base, ${unit.dbValue})';
}
