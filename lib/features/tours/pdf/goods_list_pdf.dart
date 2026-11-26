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
import 'package:warenbestand/core/pdf/widgets/pdf_totals_block.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';

/// Art der Warenliste.
enum GoodsListKind { sold, returned }

/// Daten der Warenliste einer Tour („Verkaufte Ware“ oder „Zurückgeholte Ware“).
final class GoodsListPdfData {
  /// Erzeugt die Daten.
  const GoodsListPdfData({
    required this.company,
    required this.kind,
    required this.tourNumber,
    required this.driverName,
    required this.date,
    required this.lines,
    required this.total,
  });

  final PdfCompany company;
  final GoodsListKind kind;
  final String tourNumber;
  final String driverName;
  final DateTime date;
  final List<GoodsLine> lines;

  /// Summe aller Zeilen.
  final Money total;
}

/// Warenliste mit Menge, Einzelpreis und Gesamtpreis je Produkt.
abstract final class GoodsListPdf {
  /// Erzeugt das PDF im Hintergrund.
  static Future<Uint8List> generate(
    GoodsListPdfData data,
    PdfFontBytes fonts,
  ) => PdfService.generate(builder: build, data: data, fonts: fonts);

  /// Baut das Dokument (läuft im Isolate).
  static pw.Document build(GoodsListPdfData data, PdfTheme theme) {
    final s = theme.strings;
    final labels = s.quantityLabels;
    final title = data.kind == GoodsListKind.sold
        ? s.soldGoods
        : s.returnedGoods;
    return pw.Document(title: '$title ${data.tourNumber}')..addPage(
      PdfService.letterPage(
        theme: theme,
        company: data.company,
        body: [
          PdfDocMeta.build(
            theme,
            title: title,
            fields: [
              (label: s.tourNumber, value: data.tourNumber),
              (label: s.driver, value: data.driverName),
              (label: s.date, value: DateFormatter.date(data.date)),
            ],
          ),
          ...PdfItemsTable.build(
            theme,
            columns: [
              PdfColumn.flex(s.article, flex: 3),
              PdfColumn.fixed(s.quantity, 30, alignEnd: true),
              PdfColumn.fixed(s.unitPrice, 26, alignEnd: true),
              PdfColumn.fixed(s.totalPrice, 28, alignEnd: true),
            ],
            rows: [
              for (final line in data.lines)
                [
                  line.name,
                  QuantityFormatter.format(line.quantity, labels: labels),
                  MoneyFormatter.formatPlain(line.unitPrice),
                  MoneyFormatter.formatPlain(line.total),
                ],
            ],
          ),
          PdfTotalsBlock.build(theme, [
            PdfTotalRow(
              s.totalPrice,
              MoneyFormatter.format(data.total),
              emphasized: true,
            ),
          ]),
        ],
      ),
    );
  }
}
