import 'package:pdf/widgets.dart' as pw;
import 'package:warenbestand/core/pdf/pdf_theme.dart';

/// Eine Spalte der Tabelle: Kopfzeile, Breite, Ausrichtung.
final class PdfColumn {
  /// Spalte mit Anteil an der restlichen Breite.
  const PdfColumn.flex(this.header, {this.flex = 1, this.alignEnd = false})
    : width = null;

  /// Spalte mit fester Breite in mm.
  const PdfColumn.fixed(
    this.header,
    double millimeters, {
    this.alignEnd = false,
  }) : width = millimeters,
       flex = null;

  /// Text der Kopfzeile.
  final String header;

  /// Feste Breite in mm, sonst `null`.
  final double? width;

  /// Anteil an der restlichen Breite, sonst `null`.
  final double? flex;

  /// Zahlen und Beträge rechtsbündig (am Ende der Zeile).
  final bool alignEnd;

  /// Breite für `pw.Table`.
  pw.TableColumnWidth get columnWidth => width != null
      ? pw.FixedColumnWidth(width! * PdfTheme.mm)
      : pw.FlexColumnWidth(flex!);
}

/// Generische Tabelle: Spalten frei wählbar, Kopfzeile wiederholt sich auf
/// jeder Seite, lange Texte brechen um.
abstract final class PdfItemsTable {
  /// Baut die Tabelle. [keepWithLastRow] (z. B. der Summenblock) wird mit der
  /// letzten Zeile zusammengehalten, damit er nie allein auf einer neuen Seite
  /// steht.
  static List<pw.Widget> build(
    PdfTheme theme, {
    required List<PdfColumn> columns,
    required List<List<String>> rows,
    List<pw.Widget> keepWithLastRow = const [],
  }) {
    final widths = {
      for (var i = 0; i < columns.length; i++) i: columns[i].columnWidth,
    };

    pw.Table table(List<pw.TableRow> children) => pw.Table(
      columnWidths: widths,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfTheme.line, width: 0.5),
        bottom: pw.BorderSide(color: PdfTheme.line, width: 0.5),
      ),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: children,
    );

    final header = pw.TableRow(
      repeat: true,
      decoration: const pw.BoxDecoration(color: PdfTheme.primary),
      children: [
        for (final column in columns)
          _cell(theme, column, column.header, header: true),
      ],
    );
    pw.TableRow bodyRow(List<String> values) => pw.TableRow(
      children: [
        for (var i = 0; i < columns.length; i++)
          _cell(theme, columns[i], values[i]),
      ],
    );

    if (rows.length < 2) {
      return [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            table([header, ...rows.map(bodyRow)]),
            ...keepWithLastRow,
          ],
        ),
      ];
    }
    return [
      table([header, ...rows.take(rows.length - 1).map(bodyRow)]),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          table([bodyRow(rows.last)]),
          ...keepWithLastRow,
        ],
      ),
    ];
  }

  static pw.Widget _cell(
    PdfTheme theme,
    PdfColumn column,
    String text, {
    bool header = false,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: pw.Text(
      text,
      style: header ? theme.tableHeader : theme.table,
      textAlign: column.alignEnd ? pw.TextAlign.right : pw.TextAlign.left,
    ),
  );
}
