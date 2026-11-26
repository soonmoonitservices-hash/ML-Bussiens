/// Formatiert Datum und Uhrzeit deutsch (`16.11.2026`, `16.11.2026, 14:05 Uhr`).
///
/// Erwartet bereits in Europe/Berlin umgerechnete Zeiten (`toLocal()` auf dem
/// Gerät in Deutschland); die Datenbank liefert `timestamptz`.
abstract final class DateFormatter {
  static const _months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  /// `16.11.2026`.
  static String date(DateTime value) =>
      '${_two(value.day)}.${_two(value.month)}.${value.year}';

  /// `14:05`.
  static String time(DateTime value) =>
      '${_two(value.hour)}:${_two(value.minute)}';

  /// `16.11.2026, 14:05 Uhr`.
  static String dateTime(DateTime value) =>
      '${date(value)}, ${time(value)} Uhr';

  /// `November 2026` (Monat 1–12).
  static String monthYear(int year, int month) => '${_months[month - 1]} $year';

  /// `2026-11-16` für Dateinamen und Schlüssel.
  static String iso(DateTime value) =>
      '${value.year}-${_two(value.month)}-${_two(value.day)}';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
