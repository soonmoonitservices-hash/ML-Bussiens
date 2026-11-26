import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Hinweistext auf heller Fläche (z. B. „Ware vollständig erhalten“).
abstract final class PdfNoteBlock {
  /// Baut den Block; optional mit fetter [heading].
  static pw.Widget build(PdfTheme theme, String text, {String? heading}) =>
      pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(top: 10),
        padding: const pw.EdgeInsets.all(8),
        decoration: const pw.BoxDecoration(
          color: PdfTheme.surface,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (heading != null) pw.Text(heading, style: theme.heading),
            pw.Text(text, style: theme.body),
          ],
        ),
      );
}
