import 'dart:isolate';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_strings.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_footer.dart';

/// Baut aus unveränderlichen Daten ein Dokument. Muss eine Top-Level- oder
/// statische Funktion sein, damit sie in den Isolate geschickt werden kann.
typedef PdfDocumentBuilder<T> = pw.Document Function(T data, PdfTheme theme);

/// Erzeugt PDFs im Hintergrund (Isolate), damit die App nicht hängt.
abstract final class PdfService {
  /// Erzeugt das PDF für [data]. Keine Datenbank-Aufrufe im [builder]; Bilder
  /// liegen schon als Bytes in [data].
  static Future<Uint8List> generate<T>({
    required PdfDocumentBuilder<T> builder,
    required T data,
    required PdfFontBytes fonts,
    pw.TextDirection textDirection = pw.TextDirection.ltr,
    PdfStrings strings = const PdfStrings(),
  }) => Isolate.run(() {
    final theme = PdfTheme.fromFonts(
      fonts,
      textDirection: textDirection,
      strings: strings,
    );
    return builder(data, theme).save();
  });

  /// Gemeinsame Briefseite für alle Dokumente: Firmenkopf, optional
  /// Adressfenster, [body] und Fußzeile mit Seitenzahl auf jeder Seite.
  static pw.MultiPage letterPage({
    required PdfTheme theme,
    required PdfCompany company,
    required List<pw.Widget> body,
    PdfRecipient? recipient,
    String? watermark,
  }) => pw.MultiPage(
    pageTheme: theme.pageTheme(
      background: watermark == null
          ? null
          : (_) => _watermark(theme, watermark),
    ),
    footer: (context) => PdfFooter.build(theme, company, context),
    build: (_) => [
      PdfCompanyHeader.build(theme, company),
      if (recipient != null) PdfAddressWindow.build(theme, company, recipient),
      ...body,
    ],
  );

  /// Großes diagonales Wasserzeichen („ENTWURF“).
  static pw.Widget _watermark(PdfTheme theme, String text) => pw.FullPage(
    ignoreMargins: true,
    child: pw.Center(
      child: pw.Transform.rotate(
        angle: 0.6,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            font: theme.bold,
            fontSize: 44,
            color: PdfTheme.watermark,
          ),
        ),
      ),
    ),
  );
}
