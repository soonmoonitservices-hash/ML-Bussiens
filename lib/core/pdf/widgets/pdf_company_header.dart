import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Firmendaten für Kopf, Absenderzeile und Fußzeile (aus `company_settings`).
final class PdfCompany {
  /// Erzeugt die Firmendaten.
  const PdfCompany({
    required this.name,
    required this.address,
    this.phone,
    this.email,
    this.taxNumber,
    this.vatId,
    this.iban,
    this.bic,
    this.bankName,
    this.managingDirector,
    this.logo,
    this.signature,
    this.signatureOnDeliveryNote = true,
    this.signatureOnInvoice = true,
    this.signatureScale = 100,
    this.footerText,
    this.smallBusinessNote,
  });

  /// Firmenname.
  final String name;

  /// Anschrift, mehrzeilig (Zeilen mit Zeilenumbruch getrennt).
  final String address;

  /// Telefon.
  final String? phone;

  /// E-Mail.
  final String? email;

  /// Steuernummer.
  final String? taxNumber;

  /// USt-IdNr.
  final String? vatId;

  /// IBAN.
  final String? iban;

  /// BIC.
  final String? bic;

  /// Name der Bank.
  final String? bankName;

  /// Geschäftsführer.
  final String? managingDirector;

  /// Logo als Bytes (PNG/JPEG), vorher geladen.
  final Uint8List? logo;

  /// Gespeicherte Unterschrift der Firma (PNG), vorher geladen.
  final Uint8List? signature;

  /// Unterschrift auf dem Lieferschein drucken.
  final bool signatureOnDeliveryNote;

  /// Unterschrift auf der Rechnung drucken.
  final bool signatureOnInvoice;

  /// Größe der Unterschriftsfelder in Prozent (100 = Standard).
  final int signatureScale;

  /// Fußtext der Rechnung.
  final String? footerText;

  /// Hinweis für Kleinunternehmer (§ 19 UStG).
  final String? smallBusinessNote;

  /// Anschrift als Zeilen ohne Leerzeilen.
  List<String> get addressLines => address
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

/// Firmenkopf: Logo am Anfang, Name und Anschrift am Ende. Höhe 30 mm, damit
/// das Adressfenster nach DIN 5008 Form B an der richtigen Stelle sitzt.
abstract final class PdfCompanyHeader {
  /// Baut den Kopf.
  static pw.Widget build(PdfTheme theme, PdfCompany company) {
    final logo = company.logo;
    final contact = [
      ...company.addressLines,
      if (company.phone != null) '${theme.strings.phone} ${company.phone}',
      if (company.email != null) company.email!,
    ];
    return pw.SizedBox(
      height: 30 * PdfTheme.mm,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logo != null)
            pw.SizedBox(
              height: 22 * PdfTheme.mm,
              width: 50 * PdfTheme.mm,
              child: pw.Image(
                pw.MemoryImage(logo),
                alignment: pw.Alignment.topLeft,
              ),
            )
          else
            pw.SizedBox(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(company.name, style: theme.heading),
              pw.SizedBox(height: 2),
              for (final line in contact) pw.Text(line, style: theme.label),
            ],
          ),
        ],
      ),
    );
  }
}
