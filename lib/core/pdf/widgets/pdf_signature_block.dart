import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Unterschriftsfeld: mit Bild, Name und Datum/Uhrzeit, sonst leere Linie.
abstract final class PdfSignatureBlock {
  /// Baut ein Feld. Ohne [image] bleibt Platz zum Unterschreiben.
  /// [caption] steht unter der Linie (z. B. „Unterschrift Empfänger“ oder
  /// „Name, 16.11.2026, 14:05 Uhr“). [scale] in Prozent macht Bild und Feld
  /// kleiner oder größer.
  static pw.Widget build(
    PdfTheme theme, {
    required String caption,
    Uint8List? image,
    int scale = 100,
  }) => pw.Container(
    width: 75 * PdfTheme.mm * scale / 100,
    margin: const pw.EdgeInsets.only(top: 16),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          height: 22 * PdfTheme.mm * scale / 100,
          child: image == null
              ? null
              : pw.Image(
                  pw.MemoryImage(image),
                  alignment: pw.Alignment.bottomLeft,
                ),
        ),
        pw.Container(height: 1, color: PdfTheme.text),
        pw.SizedBox(height: 3),
        pw.Text(caption, style: theme.label),
      ],
    ),
  );
}
