import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/pdf/pdf_service.dart';
import 'package:warenbestand/core/pdf/pdf_strings.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_address_window.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_doc_meta.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_items_table.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_note_block.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_totals_block.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Eine Rechnungsposition (Werte aus `invoice_items`).
final class InvoicePdfLine {
  /// Erzeugt die Position; [lineNet] kommt aus der Datenbank.
  const InvoicePdfLine({
    required this.name,
    required this.quantity,
    required this.priceNet,
    required this.vatRate,
    required this.lineNet,
  });

  /// Artikelname.
  final String name;

  /// Menge (bei Storno negativ).
  final Quantity quantity;

  /// Netto-Einzelpreis pro Basiseinheit (bei kg pro Kilogramm).
  final Money priceNet;

  /// USt-Satz.
  final VatRate vatRate;

  /// Gesamt netto der Position (aus der Datenbank).
  final Money lineNet;
}

/// Alle Daten der Rechnung. Die Summen kommen fertig aus der Datenbank, das
/// PDF rechnet nicht selbst. Die Struktur lässt sich später um ZUGFeRD/XRechnung
/// (eingebettetes XML) ergänzen, ohne das Layout zu ändern.
final class InvoicePdfData {
  /// Erzeugt die Daten.
  const InvoicePdfData({
    required this.company,
    required this.recipient,
    required this.date,
    required this.serviceDate,
    required this.dueDate,
    required this.lines,
    required this.net,
    required this.vat7,
    required this.vat19,
    required this.gross,
    this.number,
    this.note,
    this.deliveryNoteNumber,
    this.cancelsInvoiceNumber,
    this.isSmallBusiness = false,
  });

  /// Firmendaten (inkl. Bank, Steuernummer, Fußtext).
  final PdfCompany company;

  /// Empfänger.
  final PdfRecipient recipient;

  /// Rechnungsnummer; `null` solange Entwurf.
  final String? number;

  /// Rechnungsdatum.
  final DateTime date;

  /// Leistungsdatum.
  final DateTime serviceDate;

  /// Fälligkeitsdatum.
  final DateTime dueDate;

  /// Positionen.
  final List<InvoicePdfLine> lines;

  /// Nettosumme.
  final Money net;

  /// USt-Betrag 7 %.
  final Money vat7;

  /// USt-Betrag 19 %.
  final Money vat19;

  /// Gesamtbetrag brutto.
  final Money gross;

  /// Freitext der Rechnung.
  final String? note;

  /// Nummer des zugehörigen Lieferscheins.
  final String? deliveryNoteNumber;

  /// Nummer der stornierten Rechnung; gesetzt = Stornorechnung.
  final String? cancelsInvoiceNumber;

  /// Kleinunternehmer: keine USt ausweisen, Hinweis nach § 19 UStG.
  final bool isSmallBusiness;

  /// Ob ein Entwurf (ohne Nummer).
  bool get isDraft => number == null;

  /// Ob eine Stornorechnung.
  bool get isCancellation => cancelsInvoiceNumber != null;
}

/// Rechnung mit allen Pflichtangaben nach § 14 UStG.
abstract final class InvoicePdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(InvoicePdfData data, PdfFontBytes fonts) =>
      PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(InvoicePdfData data, PdfTheme theme) {
    final s = theme.strings;
    final title = data.isCancellation ? s.cancellationInvoice : s.invoice;
    final rows = [
      for (var i = 0; i < data.lines.length; i++)
        _row(data.lines[i], i + 1, s.quantityLabels),
    ];
    return pw.Document(
      title: data.number == null ? title : '$title ${data.number}',
    )..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        recipient: data.recipient,
        body: [
          PdfDocMeta.build(
            theme,
            title: title,
            fields: [
              if (data.number != null)
                (label: s.invoiceNumber, value: data.number!),
              (label: s.invoiceDate, value: DateFormatter.date(data.date)),
              (
                label: s.serviceDate,
                value: DateFormatter.date(data.serviceDate),
              ),
              if (!data.isCancellation)
                (label: s.dueDate, value: DateFormatter.date(data.dueDate)),
              if (data.deliveryNoteNumber != null)
                (label: s.deliveryNoteRef, value: data.deliveryNoteNumber!),
            ],
          ),
          if (data.cancelsInvoiceNumber != null)
            pw.Text(
              s.cancellationOf(data.cancelsInvoiceNumber!),
              style: theme.body.copyWith(font: theme.bold),
            ),
          ...PdfItemsTable.build(
            theme,
            columns: [
              PdfColumn.fixed(s.position, 10),
              PdfColumn.flex(s.article, flex: 3),
              PdfColumn.fixed(s.quantity, 16, alignEnd: true),
              PdfColumn.fixed(s.unit, 16),
              PdfColumn.fixed(s.unitPriceNet, 24, alignEnd: true),
              PdfColumn.fixed(s.vatPercent, 12, alignEnd: true),
              PdfColumn.fixed(s.lineTotalNet, 24, alignEnd: true),
            ],
            rows: rows,
            keepWithLastRow: [PdfTotalsBlock.build(theme, _totals(data, s))],
          ),
          if (!data.isCancellation && !data.isDraft)
            _paymentHint(theme, data)
          else
            pw.SizedBox(),
          if (data.isSmallBusiness && data.company.smallBusinessNote != null)
            PdfNoteBlock.build(theme, data.company.smallBusinessNote!),
          if (data.note != null && data.note!.isNotEmpty)
            PdfNoteBlock.build(theme, data.note!),
          if (data.company.footerText != null &&
              data.company.footerText!.isNotEmpty)
            PdfNoteBlock.build(theme, data.company.footerText!),
        ],
      ),
    );
  }

  static List<String> _row(
    InvoicePdfLine line,
    int position,
    QuantityLabels labels,
  ) => [
    '$position',
    line.name,
    QuantityFormatter.formatNumber(line.quantity),
    labels.unitName(line.quantity.unit, line.quantity.base),
    MoneyFormatter.formatPlain(line.priceNet),
    '${line.vatRate.percent}',
    MoneyFormatter.formatPlain(line.lineNet),
  ];

  /// Nur Steuersätze, die vorkommen.
  static List<PdfTotalRow> _totals(InvoicePdfData data, PdfStrings strings) {
    if (data.isSmallBusiness) {
      return [
        PdfTotalRow(
          strings.totalGross,
          MoneyFormatter.format(data.gross),
          emphasized: true,
        ),
      ];
    }
    bool uses(VatRate rate) => data.lines.any((l) => l.vatRate == rate);
    return [
      PdfTotalRow(strings.totalNet, MoneyFormatter.format(data.net)),
      if (uses(VatRate.reduced) || !data.vat7.isZero)
        PdfTotalRow(strings.vatAmount(7), MoneyFormatter.format(data.vat7)),
      if (uses(VatRate.standard) || !data.vat19.isZero)
        PdfTotalRow(strings.vatAmount(19), MoneyFormatter.format(data.vat19)),
      PdfTotalRow(
        strings.totalGross,
        MoneyFormatter.format(data.gross),
        emphasized: true,
      ),
    ];
  }

  static pw.Widget _paymentHint(PdfTheme theme, InvoicePdfData data) {
    final s = theme.strings;
    final company = data.company;
    final bankLines = [
      if (company.bankName != null) '${s.bank}: ${company.bankName}',
      if (company.iban != null) '${s.iban}: ${company.iban}',
      if (company.bic != null) '${s.bic}: ${company.bic}',
      if (data.number != null) s.paymentReference(data.number!),
    ];
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            s.paymentRequest(
              MoneyFormatter.format(data.gross),
              DateFormatter.date(data.dueDate),
            ),
            style: theme.body,
          ),
          pw.SizedBox(height: 3),
          for (final line in bankLines) pw.Text(line, style: theme.body),
        ],
      ),
    );
  }
}
