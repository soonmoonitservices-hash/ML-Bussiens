import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/pdf/pdf_service.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_company_header.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_doc_meta.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_image_page.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_items_table.dart';
import 'package:warenbestand/core/pdf/widgets/pdf_key_value_list.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Ein Beleg (Zeile aus `expenses`).
final class ExpensePdfItem {
  /// Erzeugt den Beleg; [net] und [gross] kommen aus der Datenbank.
  const ExpensePdfItem({
    required this.date,
    required this.title,
    required this.category,
    required this.vatRate,
    required this.net,
    required this.gross,
    this.image,
  });

  /// Belegdatum.
  final DateTime date;

  /// Bezeichnung.
  final String title;

  /// Kategorie.
  final String category;

  /// USt-Satz.
  final VatRate vatRate;

  /// Netto.
  final Money net;

  /// Brutto.
  final Money gross;

  /// Foto, vorher auf höchstens 1600 px verkleinert.
  final Uint8List? image;
}

/// Summe einer Kategorie.
final class ExpenseCategoryTotal {
  /// Erzeugt die Summe.
  const ExpenseCategoryTotal({required this.category, required this.gross});

  /// Kategorie.
  final String category;

  /// Brutto-Summe.
  final Money gross;
}

/// Alle Daten der Monatsbelege (Summen aus der Datenbank).
final class ExpensesMonthPdfData {
  /// Erzeugt die Daten.
  const ExpensesMonthPdfData({
    required this.company,
    required this.year,
    required this.month,
    required this.items,
    required this.net,
    required this.vat,
    required this.gross,
    required this.byCategory,
    this.includeCover = true,
  });

  /// Firmendaten.
  final PdfCompany company;

  /// Jahr.
  final int year;

  /// Monat 1–12.
  final int month;

  /// Belege, nach Datum sortiert.
  final List<ExpensePdfItem> items;

  /// Summe netto.
  final Money net;

  /// Summe USt.
  final Money vat;

  /// Summe brutto.
  final Money gross;

  /// Aufteilung nach Kategorie.
  final List<ExpenseCategoryTotal> byCategory;

  /// `false` für einen einzelnen Beleg (nur die Belegseite, gleicher Baustein).
  final bool includeCover;
}

/// Monatsbelege für den Steuerberater: Deckblatt, Übersicht, dann jeder Beleg
/// auf eigener Seite. Auch ein einzelner Beleg ist damit möglich.
abstract final class ExpensesMonthPdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(
    ExpensesMonthPdfData data,
    PdfFontBytes fonts,
  ) => PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(ExpensesMonthPdfData data, PdfTheme theme) {
    final s = theme.strings;
    final month = DateFormatter.monthYear(data.year, data.month);
    return pw.Document(title: s.expensesTitle(month))..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        body: [
          if (data.includeCover) ..._cover(theme, data, month),
          for (var i = 0; i < data.items.length; i++)
            ..._receiptPage(
              theme,
              data.items[i],
              i + 1,
              data.includeCover,
              startOnNewPage: data.includeCover || i > 0,
            ),
        ],
      ),
    );
  }

  static List<pw.Widget> _cover(
    PdfTheme theme,
    ExpensesMonthPdfData data,
    String month,
  ) {
    final s = theme.strings;
    return [
      PdfDocMeta.build(
        theme,
        title: s.expensesTitle(month),
        fields: [
          (label: s.receiptCount, value: '${data.items.length}'),
          (label: s.net, value: MoneyFormatter.format(data.net)),
          (label: s.vat, value: MoneyFormatter.format(data.vat)),
          (label: s.gross, value: MoneyFormatter.format(data.gross)),
        ],
      ),
      if (data.byCategory.isNotEmpty) ...[
        pw.Text(s.byCategory, style: theme.heading),
        pw.SizedBox(height: 4),
        PdfKeyValueList.build(theme, [
          for (final c in data.byCategory)
            PdfKeyValue(c.category, MoneyFormatter.format(c.gross)),
        ]),
        pw.SizedBox(height: 14),
      ],
      ...PdfItemsTable.build(
        theme,
        columns: [
          PdfColumn.fixed(s.receiptNumberShort, 10),
          PdfColumn.fixed(s.date, 20),
          PdfColumn.flex(s.title, flex: 3),
          PdfColumn.flex(s.category, flex: 2),
          PdfColumn.fixed(s.vatPercent, 12, alignEnd: true),
          PdfColumn.fixed(s.net, 22, alignEnd: true),
          PdfColumn.fixed(s.gross, 22, alignEnd: true),
        ],
        rows: [
          for (var i = 0; i < data.items.length; i++)
            [
              '${i + 1}',
              DateFormatter.date(data.items[i].date),
              data.items[i].title,
              data.items[i].category,
              '${data.items[i].vatRate.percent}',
              MoneyFormatter.formatPlain(data.items[i].net),
              MoneyFormatter.formatPlain(data.items[i].gross),
            ],
        ],
      ),
    ];
  }

  static List<pw.Widget> _receiptPage(
    PdfTheme theme,
    ExpensePdfItem item,
    int number,
    bool numbered, {
    required bool startOnNewPage,
  }) {
    final s = theme.strings;
    final caption = [
      if (numbered) '${s.receiptNumberShort} $number',
      DateFormatter.date(item.date),
      item.title,
      MoneyFormatter.format(item.gross),
    ].join(' · ');
    return PdfImagePage.build(
      theme,
      caption: caption,
      subCaption: item.image == null ? s.noPhoto : item.category,
      image: item.image,
      startOnNewPage: startOnNewPage,
    );
  }
}
