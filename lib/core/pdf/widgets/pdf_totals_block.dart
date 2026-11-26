import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Eine Summenzeile (Beschriftung und fertig formatierter Wert).
final class PdfTotalRow {
  /// Erzeugt die Zeile; [emphasized] hebt die Endsumme hervor.
  const PdfTotalRow(this.label, this.value, {this.emphasized = false});

  /// Beschriftung.
  final String label;

  /// Wert, bereits formatiert (Summen kommen aus der Datenbank).
  final String value;

  /// Fett mit Linie darüber (Gesamtbetrag).
  final bool emphasized;
}

/// Summenblock (Netto, USt, Brutto), am Zeilenende ausgerichtet.
abstract final class PdfTotalsBlock {
  /// Baut den Block.
  static pw.Widget build(PdfTheme theme, List<PdfTotalRow> rows) {
    pw.TextStyle style(PdfTotalRow row) =>
        row.emphasized ? theme.body.copyWith(font: theme.bold) : theme.body;

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.SizedBox(
          width: 80 * PdfTheme.mm,
          child: pw.Column(
            children: [
              for (final row in rows)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                  decoration: row.emphasized
                      ? const pw.BoxDecoration(
                          border: pw.Border(
                            top: pw.BorderSide(color: PdfTheme.primary),
                          ),
                        )
                      : null,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(row.label, style: style(row)),
                      pw.Text(row.value, style: style(row)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
