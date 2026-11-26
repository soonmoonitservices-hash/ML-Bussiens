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
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';

/// Eine Kennzahl mit Veränderung zum Vorzeitraum.
final class ReportPdfKpi {
  /// Erzeugt die Kennzahl; [changePercent] ist die ganze Prozentzahl.
  const ReportPdfKpi({
    required this.label,
    required this.value,
    this.changePercent,
  });

  /// Beschriftung (Umsatz, Gewinn, …).
  final String label;

  /// Wert.
  final Money value;

  /// Veränderung zum Vorzeitraum in Prozent, `null` ohne Vergleich.
  final int? changePercent;
}

/// Zeile der Top-Produkte.
final class ReportPdfProduct {
  /// Erzeugt die Zeile.
  const ReportPdfProduct({
    required this.name,
    required this.sold,
    required this.revenue,
  });

  /// Produktname.
  final String name;

  /// Verkaufte Menge.
  final Quantity sold;

  /// Umsatz netto.
  final Money revenue;
}

/// Ausgaben einer Kategorie.
final class ReportPdfCategory {
  /// Erzeugt die Zeile.
  const ReportPdfCategory({required this.category, required this.amount});

  /// Kategorie.
  final String category;

  /// Summe.
  final Money amount;
}

/// Zeile der Fahrerstatistik.
final class ReportPdfDriver {
  /// Erzeugt die Zeile.
  const ReportPdfDriver({
    required this.name,
    required this.tours,
    required this.revenue,
    required this.averagePerTour,
    required this.returnRatePercent,
    required this.differenceTotal,
  });

  /// Fahrer.
  final String name;

  /// Anzahl Touren.
  final int tours;

  /// Umsatz.
  final Money revenue;

  /// Ø Umsatz pro Tour.
  final Money averagePerTour;

  /// Rücklaufquote nach Wert, ganze Prozent.
  final int returnRatePercent;

  /// Summe der Kassendifferenzen.
  final Money differenceTotal;
}

/// Alle Daten des Berichts (Werte aus den `report_*`-Funktionen).
final class ReportPdfData {
  /// Erzeugt die Daten.
  const ReportPdfData({
    required this.company,
    required this.from,
    required this.to,
    required this.kpis,
    required this.topProducts,
    required this.expensesByCategory,
    required this.drivers,
  });

  /// Firmendaten.
  final PdfCompany company;

  /// Beginn des Zeitraums.
  final DateTime from;

  /// Ende des Zeitraums.
  final DateTime to;

  /// Kennzahlen.
  final List<ReportPdfKpi> kpis;

  /// Top-Produkte.
  final List<ReportPdfProduct> topProducts;

  /// Ausgaben nach Kategorie.
  final List<ReportPdfCategory> expensesByCategory;

  /// Fahrerstatistik.
  final List<ReportPdfDriver> drivers;
}

/// Auswertungsbericht mit Kennzahlen, Tabellen und einfachen Balkendiagrammen.
abstract final class ReportPdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(ReportPdfData data, PdfFontBytes fonts) =>
      PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(ReportPdfData data, PdfTheme theme) {
    final s = theme.strings;
    return pw.Document(title: s.report)..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        body: [
          PdfDocMeta.build(
            theme,
            title: s.report,
            fields: [
              (
                label: s.period,
                value:
                    '${DateFormatter.date(data.from)} – ${DateFormatter.date(data.to)}',
              ),
            ],
          ),
          pw.Text(s.kpis, style: theme.heading),
          pw.SizedBox(height: 4),
          ...PdfItemsTable.build(
            theme,
            columns: [
              PdfColumn.flex(s.kpis, flex: 3),
              PdfColumn.fixed(s.amount, 32, alignEnd: true),
              PdfColumn.fixed(s.changeToPrevious, 36, alignEnd: true),
            ],
            rows: [
              for (final kpi in data.kpis)
                [
                  kpi.label,
                  MoneyFormatter.format(kpi.value),
                  _changeText(kpi.changePercent, s.notAvailable),
                ],
            ],
          ),
          if (data.topProducts.isNotEmpty) ...[
            _section(theme, s.topProducts),
            ...PdfItemsTable.build(
              theme,
              columns: [
                PdfColumn.flex(s.article, flex: 3),
                PdfColumn.fixed(s.quantity, 28, alignEnd: true),
                PdfColumn.fixed(s.revenue, 28, alignEnd: true),
              ],
              rows: [
                for (final p in data.topProducts)
                  [
                    p.name,
                    QuantityFormatter.format(p.sold, labels: s.quantityLabels),
                    MoneyFormatter.format(p.revenue),
                  ],
              ],
            ),
            pw.SizedBox(height: 6),
            _bars(theme, [
              for (final p in data.topProducts)
                (
                  label: p.name,
                  value: p.revenue.cents,
                  text: MoneyFormatter.format(p.revenue),
                ),
            ]),
          ],
          if (data.expensesByCategory.isNotEmpty) ...[
            _section(theme, s.expensesByCategory),
            _bars(theme, [
              for (final c in data.expensesByCategory)
                (
                  label: c.category,
                  value: c.amount.cents,
                  text: MoneyFormatter.format(c.amount),
                ),
            ]),
          ],
          if (data.drivers.isNotEmpty) ...[
            _section(theme, s.driverStats),
            ...PdfItemsTable.build(
              theme,
              columns: [
                PdfColumn.flex(s.driver, flex: 2),
                PdfColumn.fixed(s.tours, 14, alignEnd: true),
                PdfColumn.fixed(s.revenue, 26, alignEnd: true),
                PdfColumn.fixed(s.averagePerTour, 26, alignEnd: true),
                PdfColumn.fixed(s.returnRate, 18, alignEnd: true),
                PdfColumn.fixed(s.differences, 24, alignEnd: true),
              ],
              rows: [
                for (final d in data.drivers)
                  [
                    d.name,
                    '${d.tours}',
                    MoneyFormatter.formatPlain(d.revenue),
                    MoneyFormatter.formatPlain(d.averagePerTour),
                    '${d.returnRatePercent} %',
                    MoneyFormatter.formatSigned(d.differenceTotal),
                  ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _changeText(int? value, String fallback) =>
      value == null ? fallback : '${value > 0 ? '+' : ''}$value %';

  static pw.Widget _section(PdfTheme theme, String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 4),
    child: pw.Text(title, style: theme.heading),
  );

  /// Einfaches Balkendiagramm aus pdf-Widgets (kein Screenshot).
  static pw.Widget _bars(
    PdfTheme theme,
    List<({String label, int value, String text})> items,
  ) {
    final maxValue = items.fold<int>(1, (m, i) => i.value > m ? i.value : m);
    const scale = 1000;
    return pw.Column(
      children: [
        for (final item in items)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 40 * PdfTheme.mm,
                  child: pw.Text(item.label, style: theme.table, maxLines: 1),
                ),
                pw.Expanded(
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex:
                            (item.value.clamp(0, maxValue) * scale ~/ maxValue)
                                .clamp(1, scale),
                        child: pw.Container(height: 8, color: PdfTheme.primary),
                      ),
                      pw.Expanded(
                        flex:
                            scale -
                            (item.value.clamp(0, maxValue) * scale ~/ maxValue)
                                .clamp(1, scale) +
                            1,
                        child: pw.SizedBox(),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(
                  width: 26 * PdfTheme.mm,
                  child: pw.Text(
                    item.text,
                    style: theme.table,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
