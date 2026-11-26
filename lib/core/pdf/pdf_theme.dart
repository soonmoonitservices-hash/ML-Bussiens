import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_strings.dart';

/// Schriftdateien als Bytes, damit sie in den Isolate übergeben werden können.
final class PdfFontBytes {
  /// Erzeugt die Schriften aus Bytes (z. B. aus den Assets).
  const PdfFontBytes({
    required this.regular,
    required this.medium,
    required this.bold,
    this.arabic,
  });

  /// Lädt IBM Plex Sans aus den App-Assets.
  static Future<PdfFontBytes> fromAssets() async {
    Future<Uint8List> load(String name) async =>
        (await rootBundle.load('assets/fonts/$name')).buffer.asUint8List();
    return PdfFontBytes(
      regular: await load('plex/IBMPlexSans-Regular.ttf'),
      medium: await load('plex/IBMPlexSans-Medium.ttf'),
      bold: await load('plex/IBMPlexSans-SemiBold.ttf'),
      arabic: await load('plex/IBMPlexSansArabic-Regular.ttf'),
    );
  }

  /// IBM Plex Sans Regular.
  final Uint8List regular;

  /// IBM Plex Sans Medium.
  final Uint8List medium;

  /// IBM Plex Sans SemiBold (fett im PDF).
  final Uint8List bold;

  /// IBM Plex Sans Arabic als Ersatzschrift für arabische Namen.
  final Uint8List? arabic;
}

/// Gemeinsames Aussehen aller PDFs: A4, Ränder, Schriften, Farben, Größen.
final class PdfTheme {
  /// Erzeugt das Theme aus geladenen Schriften.
  PdfTheme({
    required this.regular,
    required this.medium,
    required this.bold,
    this.fallback = const [],
    this.textDirection = pw.TextDirection.ltr,
    this.strings = const PdfStrings(),
  });

  /// Baut Schriften aus Bytes (läuft im Isolate).
  factory PdfTheme.fromFonts(
    PdfFontBytes fonts, {
    pw.TextDirection textDirection = pw.TextDirection.ltr,
    PdfStrings strings = const PdfStrings(),
  }) => PdfTheme(
    regular: pw.Font.ttf(ByteData.sublistView(fonts.regular)),
    medium: pw.Font.ttf(ByteData.sublistView(fonts.medium)),
    bold: pw.Font.ttf(ByteData.sublistView(fonts.bold)),
    fallback: [
      if (fonts.arabic != null)
        pw.Font.ttf(ByteData.sublistView(fonts.arabic!)),
    ],
    textDirection: textDirection,
    strings: strings,
  );

  /// Millimeter in PDF-Punkten.
  static const double mm = PdfPageFormat.mm;

  /// Dunkelgrün für Überschriften und Tabellenköpfe.
  static const PdfColor primary = PdfColor.fromInt(0xFF0B4A2E);

  /// Fast schwarzer Text.
  static const PdfColor text = PdfColor.fromInt(0xFF1A1A1A);

  /// Gedämpfter Text (Beschriftungen).
  static const PdfColor muted = PdfColor.fromInt(0xFF5F6B66);

  /// Hellgraue Linien.
  static const PdfColor line = PdfColor.fromInt(0xFFD0D5D2);

  /// Sehr helle Fläche für Hinweisblöcke.
  static const PdfColor surface = PdfColor.fromInt(0xFFF2F4F3);

  /// Sehr helles Grau für Wasserzeichen.
  static const PdfColor watermark = PdfColor.fromInt(0xFFE3E6E5);

  /// Rot für Fehlbeträge.
  static const PdfColor negative = PdfColor.fromInt(0xFFB3261E);

  /// Grün für Überschüsse.
  static const PdfColor positive = PdfColor.fromInt(0xFF1B7A3E);

  /// Seitenränder in mm.
  static const double marginLeft = 25;
  static const double marginRight = 20;
  static const double marginTop = 15;
  static const double marginBottom = 25;

  /// IBM Plex Sans Regular.
  final pw.Font regular;

  /// IBM Plex Sans Medium.
  final pw.Font medium;

  /// IBM Plex Sans SemiBold (fett im PDF).
  final pw.Font bold;

  /// Ersatzschriften für Zeichen, die Plex Sans nicht hat (Arabisch).
  final List<pw.Font> fallback;

  /// Schreibrichtung (für Arabisch später `rtl`).
  final pw.TextDirection textDirection;

  /// Alle Texte.
  final PdfStrings strings;

  /// Fließtext 10 pt.
  pw.TextStyle get body => pw.TextStyle(
    fontFallback: fallback,
    font: regular,
    fontSize: 10,
    color: text,
  );

  /// Beschriftung (gedämpft) 9 pt.
  pw.TextStyle get label => pw.TextStyle(
    fontFallback: fallback,
    font: regular,
    fontSize: 9,
    color: muted,
  );

  /// Tabellentext 9 pt.
  pw.TextStyle get table => pw.TextStyle(
    fontFallback: fallback,
    font: regular,
    fontSize: 9,
    color: text,
  );

  /// Tabellenkopf 9 pt, weiß auf Dunkelgrün.
  pw.TextStyle get tableHeader => pw.TextStyle(
    fontFallback: fallback,
    font: bold,
    fontSize: 9,
    color: PdfColors.white,
  );

  /// Fußzeile 7,5 pt.
  pw.TextStyle get footer => pw.TextStyle(
    fontFallback: fallback,
    font: regular,
    fontSize: 7.5,
    color: muted,
  );

  /// Titel 16 pt fett.
  pw.TextStyle get title => pw.TextStyle(
    fontFallback: fallback,
    font: bold,
    fontSize: 16,
    color: primary,
  );

  /// Zwischenüberschrift 11 pt fett.
  pw.TextStyle get heading => pw.TextStyle(
    fontFallback: fallback,
    font: bold,
    fontSize: 11,
    color: primary,
  );

  /// Seiteneinstellungen: A4 hochkant mit den Rändern, optional Hintergrund.
  pw.PageTheme pageTheme({pw.BuildCallback? background}) => pw.PageTheme(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(
      marginLeft * mm,
      marginTop * mm,
      marginRight * mm,
      marginBottom * mm,
    ),
    textDirection: textDirection,
    theme: pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: fallback,
    ),
    buildBackground: background,
  );
}
