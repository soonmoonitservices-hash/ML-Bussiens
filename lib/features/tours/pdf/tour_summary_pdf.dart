import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/pdf/pdf_service.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_doc_meta.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_items_table.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_key_value_list.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_signature_block.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

/// Eine Position der Tour.
final class TourPdfLine {
  /// Erzeugt die Position.
  const TourPdfLine({
    required this.name,
    required this.loaded,
    required this.returned,
    required this.sellPrice,
    required this.revenue,
    this.gift,
  });

  /// Verschenkte Menge (kein Umsatz).
  final Quantity? gift;

  /// Artikelname.
  final String name;

  /// Geladene Menge.
  final Quantity loaded;

  /// Zurückgebrachte Menge.
  final Quantity returned;

  /// Netto-Verkaufspreis pro Basiseinheit.
  final Money sellPrice;

  /// Umsatz netto der Position.
  final Money revenue;

  /// Bezahlte Menge = geladen − zurück − geschenkt.
  Quantity get sold => loaded - returned - (gift ?? Quantity.zero(loaded.unit));
}

/// Eine Ausgabe der Tour.
final class TourPdfExpense {
  /// Erzeugt die Ausgabe.
  const TourPdfExpense({required this.title, required this.gross});

  /// Art (Diesel, Essen, …).
  final String title;

  /// Betrag brutto.
  final Money gross;
}

/// Alle Daten der Tourabrechnung (Summen aus der Datenbank).
final class TourSummaryPdfData {
  /// Erzeugt die Daten.
  const TourSummaryPdfData({
    required this.company,
    required this.tourNumber,
    required this.driverName,
    required this.date,
    required this.lines,
    required this.expenses,
    required this.revenue,
    required this.expensesGross,
    required this.expectedCash,
    required this.cashReceived,
    required this.difference,
    required this.cost,
    required this.profit,
    this.startedAt,
    this.closedAt,
    this.differenceReason,
  });

  /// Firmendaten.
  final PdfCompany company;

  /// Tour-Nummer.
  final String tourNumber;

  /// Fahrer.
  final String driverName;

  /// Datum der Tour.
  final DateTime date;

  /// Start.
  final DateTime? startedAt;

  /// Abschluss.
  final DateTime? closedAt;

  /// Positionen.
  final List<TourPdfLine> lines;

  /// Ausgaben.
  final List<TourPdfExpense> expenses;

  /// Umsatz netto.
  final Money revenue;

  /// Ausgaben brutto.
  final Money expensesGross;

  /// Soll-Bargeld.
  final Money expectedCash;

  /// Übergebenes Bargeld.
  final Money cashReceived;

  /// Differenz (negativ = weniger Bargeld als erwartet). Sie geht in den Gewinn ein.
  final Money difference;

  /// Begründung der Differenz.
  final String? differenceReason;

  /// Wareneinsatz.
  final Money cost;

  /// Tourgewinn.
  final Money profit;
}

/// Tourabrechnung mit leeren Unterschriftsfeldern „Fahrer“ und „Geprüft“.
abstract final class TourSummaryPdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(
    TourSummaryPdfData data,
    PdfFontBytes fonts,
  ) => PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(TourSummaryPdfData data, PdfTheme theme) {
    final s = theme.strings;
    final labels = s.quantityLabels;
    final rows = [
      for (final line in data.lines)
        [
          if (line.gift != null && line.gift!.base > 0)
            '${line.name} (${QuantityFormatter.format(line.gift!, labels: labels)} geschenkt)'
          else
            line.name,
          QuantityFormatter.format(line.loaded, labels: labels),
          QuantityFormatter.format(line.returned, labels: labels),
          QuantityFormatter.format(line.sold, labels: labels),
          MoneyFormatter.formatPlain(line.sellPrice),
          MoneyFormatter.formatPlain(line.revenue),
        ],
    ];
    final differenceText = data.difference.isZero
        ? s.cashBalanced
        : data.difference.isNegative
        ? '${s.shortfall} ${MoneyFormatter.formatSigned(data.difference)}'
        : '${s.surplus} ${MoneyFormatter.formatSigned(data.difference)}';
    final differenceColor = data.difference.isZero
        ? PdfTheme.text
        : data.difference.isNegative
        ? PdfTheme.negative
        : PdfTheme.positive;

    return pw.Document(title: '${s.tourSummary} ${data.tourNumber}')..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        body: [
          PdfDocMeta.build(
            theme,
            title: s.tourSummary,
            fields: [
              (label: s.tourNumber, value: data.tourNumber),
              (label: s.driver, value: data.driverName),
              (label: s.date, value: DateFormatter.date(data.date)),
              if (data.startedAt != null)
                (
                  label: s.startedAt,
                  value: DateFormatter.dateTime(data.startedAt!),
                ),
              if (data.closedAt != null)
                (
                  label: s.closedAt,
                  value: DateFormatter.dateTime(data.closedAt!),
                ),
            ],
          ),
          ...PdfItemsTable.build(
            theme,
            columns: [
              PdfColumn.flex(s.article, flex: 3),
              PdfColumn.fixed(s.loaded, 22, alignEnd: true),
              PdfColumn.fixed(s.returned, 22, alignEnd: true),
              PdfColumn.fixed(s.sold, 22, alignEnd: true),
              PdfColumn.fixed(s.price, 18, alignEnd: true),
              PdfColumn.fixed(s.revenue, 22, alignEnd: true),
            ],
            rows: rows,
          ),
          if (data.expenses.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text(s.expenses, style: theme.heading),
            pw.SizedBox(height: 4),
            ...PdfItemsTable.build(
              theme,
              columns: [
                PdfColumn.flex(s.type, flex: 3),
                PdfColumn.fixed(s.amount, 30, alignEnd: true),
              ],
              rows: [
                for (final e in data.expenses)
                  [e.title, MoneyFormatter.format(e.gross)],
              ],
            ),
          ],
          pw.SizedBox(height: 16),
          pw.Column(
            children: [
              PdfKeyValueList.build(theme, [
                PdfKeyValue(s.revenue, MoneyFormatter.format(data.revenue)),
                PdfKeyValue(
                  s.expenses,
                  MoneyFormatter.format(data.expensesGross),
                ),
                PdfKeyValue(
                  s.expectedCash,
                  MoneyFormatter.format(data.expectedCash),
                ),
                PdfKeyValue(
                  s.cashReceived,
                  MoneyFormatter.format(data.cashReceived),
                ),
                PdfKeyValue(
                  s.difference,
                  differenceText,
                  valueColor: differenceColor,
                  bold: true,
                ),
                if (data.differenceReason != null &&
                    data.differenceReason!.isNotEmpty)
                  PdfKeyValue(s.differenceReason, data.differenceReason!),
                PdfKeyValue(s.cost, MoneyFormatter.format(data.cost)),
                PdfKeyValue(
                  s.profit,
                  MoneyFormatter.format(data.profit),
                  bold: true,
                ),
              ]),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  PdfSignatureBlock.build(theme, caption: s.driver),
                  PdfSignatureBlock.build(theme, caption: s.checked),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
