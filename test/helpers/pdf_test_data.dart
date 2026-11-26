import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';

/// Plex-Schriften direkt aus den Assets (ohne Flutter-Bundle).
PdfFontBytes loadTestFonts() => PdfFontBytes(
  regular: File('assets/fonts/plex/IBMPlexSans-Regular.ttf').readAsBytesSync(),
  medium: File('assets/fonts/plex/IBMPlexSans-Medium.ttf').readAsBytesSync(),
  bold: File('assets/fonts/plex/IBMPlexSans-SemiBold.ttf').readAsBytesSync(),
  arabic: File('assets/fonts/plex/IBMPlexSansArabic-Regular.ttf')
      .readAsBytesSync(),
);

/// 1×1-PNG als Platzhalter für Logo, Unterschrift und Belegfoto.
final Uint8List tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Beispiel-Firma mit allen Feldern.
PdfCompany testCompany({bool withLogo = true}) => PdfCompany(
  name: 'Rasho Feinkost GmbH',
  address: 'Musterstraße 1\n10115 Berlin',
  phone: '030 123456',
  email: 'info@example.de',
  taxNumber: '12/345/67890',
  vatId: 'DE123456789',
  iban: 'DE02120300000000202051',
  bic: 'BYLADEM1001',
  bankName: 'Testbank',
  managingDirector: 'Max Mustermann',
  logo: withLogo ? tinyPng : null,
  footerText: 'Vielen Dank für Ihren Auftrag.',
);

/// Beispiel-Empfänger.
const testRecipient = PdfRecipient(
  name: 'Feinkost Kaya',
  address: 'Hauptstraße 5\n12345 Köln',
);

/// Anzahl der Seiten eines PDFs.
int pageCount(Uint8List pdf) =>
    RegExp(r'/Type\s*/Page(?![a-z])')
        .allMatches(latin1.decode(pdf, allowInvalid: true))
        .length;

/// Ob die Bytes ein PDF sind.
bool isPdf(Uint8List bytes) => latin1.decode(bytes.sublist(0, 5)) == '%PDF-';
