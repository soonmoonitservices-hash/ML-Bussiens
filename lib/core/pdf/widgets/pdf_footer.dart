import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';

/// Fußzeile auf jeder Seite: Firma · Bank · Steuernr. · USt-IdNr. ·
/// Geschäftsführer und „Seite X von Y“.
abstract final class PdfFooter {
  /// Baut die Fußzeile.
  static pw.Widget build(
    PdfTheme theme,
    PdfCompany company,
    pw.Context context,
  ) {
    final s = theme.strings;
    final bank = [
      if (company.bankName != null) company.bankName!,
      if (company.iban != null) '${s.iban} ${company.iban}',
      if (company.bic != null) '${s.bic} ${company.bic}',
    ].join(' · ');
    final parts = [
      company.name,
      if (bank.isNotEmpty) bank,
      if (company.taxNumber != null) '${s.taxNumber} ${company.taxNumber}',
      if (company.vatId != null) '${s.vatId} ${company.vatId}',
      if (company.managingDirector != null)
        '${s.managingDirector}: ${company.managingDirector}',
    ];
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfTheme.line, width: 0.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            parts.join(' · '),
            style: theme.footer,
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            s.pageOf(context.pageNumber, context.pagesCount),
            style: theme.footer,
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
}
