import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Einheitennamen für Mengenanzeigen in der Sprache der App.
extension QuantityLabelsFromStrings on AppLocalizations {
  QuantityLabels get quantityLabels => QuantityLabels(
    carton: unitCartonOne,
    cartons: cartons,
    piece: unitPiece,
    pieces: unitPiece,
    jar: unitJarOne,
    jars: unitJarMany,
    kg: unitKgShort,
  );
}
