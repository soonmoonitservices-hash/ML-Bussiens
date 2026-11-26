import 'package:warenbestand/core/formatting/date_formatter.dart';

/// Dateinamen und Speicherpfade der PDFs.
abstract final class PdfFileName {
  /// `Lieferschein_LS-2026-001_Feinkost-Kaya.pdf`.
  static String deliveryNote({
    required String number,
    required String recipient,
  }) => _join(['Lieferschein', number, recipient]);

  /// `Rechnung_RE-2026-001_Feinkost-Kaya.pdf`.
  static String invoice({required String number, required String recipient}) =>
      _join(['Rechnung', number, recipient]);

  /// `Stornorechnung_RE-2026-005.pdf`.
  static String cancellationInvoice({required String number}) =>
      _join(['Stornorechnung', number]);

  /// `Tourabrechnung_T-2026-012_Mehmet-Yilmaz_2026-11-16.pdf`.
  static String tourSummary({
    required String number,
    required String driver,
    required DateTime date,
  }) => _join(['Tourabrechnung', number, driver, DateFormatter.iso(date)]);

  /// `Belege_2026-11.pdf`.
  static String expensesMonth({required int year, required int month}) =>
      _join(['Belege', '$year-${month.toString().padLeft(2, '0')}']);

  /// `Belege_Auswahl_2026-11-05_bis_2026-11-23.pdf` für ausgewählte Belege.
  static String expensesSelection({
    required DateTime from,
    required DateTime to,
  }) => _join([
    'Belege',
    'Auswahl',
    DateFormatter.iso(from),
    'bis',
    DateFormatter.iso(to),
  ]);

  /// `Beleg_2026-11-16_Diesel.pdf` für einen einzelnen Beleg.
  static String expense({required DateTime date, required String title}) =>
      _join(['Beleg', DateFormatter.iso(date), title]);

  /// `Verkaufte-Ware_T-2026-001.pdf` bzw. `Zurückgeholte-Ware_T-2026-001.pdf`.
  static String goodsList({
    required String title,
    required String tourNumber,
  }) => _join([title, tourNumber]);

  /// `Auswertung_2026-11-01_bis_2026-11-30.pdf`.
  static String report({required DateTime from, required DateTime to}) => _join(
    ['Auswertung', DateFormatter.iso(from), 'bis', DateFormatter.iso(to)],
  );

  /// Pfad im Bucket `documents`: `{jahr}/{typ}/{nummer}.pdf`
  /// (nur für unterschriebene Lieferscheine und festgeschriebene Rechnungen).
  static String storagePath({
    required int year,
    required String type,
    required String number,
  }) => '$year/${sanitize(type)}/${sanitize(number)}.pdf';

  /// Macht einen Text dateinamentauglich: Umlaute ersetzen (ä → ae, ß → ss),
  /// Akzente entfernen, Leerzeichen → Bindestrich, alles andere weglassen.
  static String sanitize(String input) {
    final buffer = StringBuffer();
    for (final rune in input.trim().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_replacements[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^A-Za-z0-9\-]'), '')
        .replaceAll(RegExp('-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Teile mit `_` verbinden; leere Teile entfallen.
  static String _join(List<String> parts) {
    final cleaned = parts.map(sanitize).where((part) => part.isNotEmpty);
    return '${cleaned.join('_')}.pdf';
  }

  static const _replacements = {
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'Ä': 'Ae',
    'Ö': 'Oe',
    'Ü': 'Ue',
    'ß': 'ss',
    '_': '-',
    '/': '-',
    '.': '-',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'í': 'i',
    'î': 'i',
    'ó': 'o',
    'ô': 'o',
    'ú': 'u',
    'û': 'u',
    'ç': 'c',
    'ñ': 'n',
    'ş': 's',
    'ğ': 'g',
    'ı': 'i',
    'İ': 'I',
    'É': 'E',
  };
}
