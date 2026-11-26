import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Eine Zeile „Wareneinsatz ........ 517,60 €“.
final class PdfKeyValue {
  /// Erzeugt die Zeile; [valueColor] z. B. rot für Fehlbeträge.
  const PdfKeyValue(
    this.label,
    this.value, {
    this.valueColor,
    this.bold = false,
  });

  /// Beschriftung.
  final String label;

  /// Wert, bereits formatiert.
  final String value;

  /// Farbe des Werts, sonst Textfarbe.
  final PdfColor? valueColor;

  /// Fett.
  final bool bold;
}

/// Liste aus Beschriftung, Punktlinie und Wert.
abstract final class PdfKeyValueList {
  /// Baut die Liste.
  static pw.Widget build(PdfTheme theme, List<PdfKeyValue> items) => pw.Column(
    children: [
      for (final item in items)
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                item.label,
                style: item.bold
                    ? theme.body.copyWith(font: theme.bold)
                    : theme.body,
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 1,
                  margin: const pw.EdgeInsets.symmetric(horizontal: 4),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfTheme.line,
                        style: pw.BorderStyle.dotted,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Text(
                item.value,
                style: theme.body.copyWith(
                  font: item.bold ? theme.bold : theme.medium,
                  color: item.valueColor ?? PdfTheme.text,
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
