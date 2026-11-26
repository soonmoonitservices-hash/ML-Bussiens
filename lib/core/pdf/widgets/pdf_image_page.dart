import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Ein Belegfoto pro Seite, eingepasst (Seitenverhältnis bleibt), mit
/// Bildunterschrift. Beginnt mit einem Seitenumbruch und gehört in dieselbe
/// `MultiPage` wie der Rest, damit „Seite X von Y“ durchgehend stimmt.
abstract final class PdfImagePage {
  /// Baut die Seite. Ohne [image] bleibt nur die Datenzeile.
  static List<pw.Widget> build(
    PdfTheme theme, {
    required String caption,
    String? subCaption,
    Uint8List? image,
    bool startOnNewPage = true,
  }) => [
    if (startOnNewPage) pw.NewPage(),
    pw.Text(caption, style: theme.heading),
    if (subCaption != null) pw.Text(subCaption, style: theme.label),
    pw.SizedBox(height: 8),
    if (image != null)
      pw.SizedBox(
        height: 180 * PdfTheme.mm,
        child: pw.Center(child: pw.Image(pw.MemoryImage(image))),
      ),
  ];
}
