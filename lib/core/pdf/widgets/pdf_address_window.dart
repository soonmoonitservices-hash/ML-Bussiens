import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';

/// Empfänger (Name und Anschrift, frei eingetippt).
final class PdfRecipient {
  /// Erzeugt den Empfänger.
  const PdfRecipient({required this.name, this.address = ''});

  /// Name.
  final String name;

  /// Anschrift, mehrzeilig.
  final String address;

  /// Name und Anschriftzeilen ohne Leerzeilen.
  List<String> get lines => [
    name,
    ...address.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty),
  ];
}

/// Anschriftfeld nach DIN 5008 Form B (85 × 45 mm, 45 mm unter der Oberkante):
/// kleine Absenderzeile (5 mm) darüber, darunter die Empfängeranschrift.
abstract final class PdfAddressWindow {
  /// Baut das Adressfenster.
  static pw.Widget build(
    PdfTheme theme,
    PdfCompany company,
    PdfRecipient recipient,
  ) {
    final senderLine = [
      company.name,
      if (company.addressLines.isNotEmpty) company.addressLines.join(', '),
    ].join(' · ');
    return pw.SizedBox(
      width: 85 * PdfTheme.mm,
      height: 45 * PdfTheme.mm,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            height: 5 * PdfTheme.mm,
            child: pw.Text(
              senderLine,
              maxLines: 1,
              style: theme.footer.copyWith(
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 2),
          for (final line in recipient.lines) pw.Text(line, style: theme.body),
        ],
      ),
    );
  }
}
