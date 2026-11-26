import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Titel mit Kennfeldern (Nummer, Datum, …) als zweispaltige Tabelle.
abstract final class PdfDocMeta {
  /// Baut Titel und Felder; Felder ohne Wert vorher weglassen.
  static pw.Widget build(
    PdfTheme theme, {
    required String title,
    required List<({String label, String value})> fields,
  }) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.SizedBox(height: 8 * PdfTheme.mm),
      pw.Text(title, style: theme.title),
      pw.SizedBox(height: 8),
      pw.Table(
        columnWidths: {
          0: const pw.FixedColumnWidth(38 * PdfTheme.mm),
          1: const pw.FlexColumnWidth(),
        },
        children: [
          for (final field in fields)
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Text(field.label, style: theme.label),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                  child: pw.Text(field.value, style: theme.table),
                ),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 10),
    ],
  );
}
