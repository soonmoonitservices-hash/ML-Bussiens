import 'package:warenbestand/core/value_objects/quantity.dart';

/// Einheitennamen für die Mengenanzeige (Einzahl und Mehrzahl).
final class QuantityLabels {
  /// Erzeugt die Bezeichnungen.
  const QuantityLabels({
    required this.carton,
    required this.cartons,
    required this.piece,
    required this.pieces,
    required this.jar,
    required this.jars,
    required this.kg,
  });

  /// Deutsche Bezeichnungen.
  static const de = QuantityLabels(
    carton: 'Karton',
    cartons: 'Kartons',
    piece: 'Stück',
    pieces: 'Stück',
    jar: 'Glas',
    jars: 'Gläser',
    kg: 'kg',
  );

  /// Ein Karton.
  final String carton;

  /// Mehrere Kartons.
  final String cartons;

  /// Ein Stück.
  final String piece;

  /// Mehrere Stück.
  final String pieces;

  /// Ein Glas.
  final String jar;

  /// Mehrere Gläser.
  final String jars;

  /// Kilogramm.
  final String kg;

  /// Name der Basiseinheit passend zur Anzahl.
  String unitName(ProductUnit unit, int count) => switch (unit) {
    ProductUnit.carton => count == 1 ? carton : cartons,
    ProductUnit.piece => count == 1 ? piece : pieces,
    ProductUnit.jar => count == 1 ? jar : jars,
    ProductUnit.kg => kg,
  };
}

/// Formatiert Mengen: `55 Gläser`, `12,5 kg`, `13 Kartons + 3 Gläser`.
abstract final class QuantityFormatter {
  /// Menge in Basiseinheit mit Einheit (`55 Gläser`, `12,5 kg`).
  static String format(
    Quantity quantity, {
    QuantityLabels labels = QuantityLabels.de,
  }) =>
      '${formatNumber(quantity)} ${labels.unitName(quantity.unit, quantity.base)}';

  /// Nur die Zahl (`55`, `12,5`); Kilogramm mit Komma, ohne unnötige Nullen.
  static String formatNumber(Quantity quantity) {
    if (!quantity.unit.isWeight) {
      return quantity.base.toString();
    }
    final kilograms = quantity.base ~/ 1000;
    final rest = (quantity.base % 1000).toString().padLeft(3, '0');
    final fraction = rest.replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$kilograms' : '$kilograms,$fraction';
  }

  /// Zusatz für Karton-Produkte: `13 Kartons + 3 Gläser`; `null` ohne Karton.
  static String? cartonBreakdown(
    Quantity quantity,
    int? unitsPerCarton, {
    QuantityLabels labels = QuantityLabels.de,
  }) {
    if (unitsPerCarton == null ||
        unitsPerCarton <= 0 ||
        quantity.unit.isWeight) {
      return null;
    }
    final split = quantity.splitIntoCartons(unitsPerCarton);
    final cartonText =
        '${split.cartons} ${split.cartons == 1 ? labels.carton : labels.cartons}';
    if (split.loosePieces == 0) {
      return cartonText;
    }
    final looseText =
        '${split.loosePieces} ${labels.unitName(quantity.unit, split.loosePieces)}';
    return split.cartons == 0 ? looseText : '$cartonText + $looseText';
  }
}
