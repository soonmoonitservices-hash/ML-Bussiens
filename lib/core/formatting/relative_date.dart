import 'package:warenbestand/core/formatting/date_formatter.dart';

/// Wörter für relative Datumsangaben (kommen aus den ARB-Dateien).
final class RelativeDateLabels {
  const RelativeDateLabels({
    required this.today,
    required this.yesterday,
    required this.weekdayShort,
    required this.dueToday,
    required this.dueIn,
    required this.overdueSince,
  });

  final String today;
  final String yesterday;

  /// Kurzer Wochentag, z. B. `Mo.`.
  final String Function(DateTime date) weekdayShort;
  final String dueToday;
  final String Function(int days) dueIn;
  final String Function(int days) overdueSince;
}

/// Wie lange eine Rechnung noch offen sein darf.
enum DueState { upcoming, today, overdue }

/// Ergebnis von [RelativeDate.due].
final class DueLabel {
  const DueLabel(this.text, this.state);

  final String text;
  final DueState state;
}

/// Relative Datumsangaben: „Heute, 08:30“, „Gestern“, „Mo., 16.11.“,
/// sonst „16.11.2026“; Fälligkeit als „fällig in 3 Tagen“.
abstract final class RelativeDate {
  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// [withTime]: bei „Heute“ und „Gestern“ die Uhrzeit anhängen.
  static String format(
    RelativeDateLabels labels,
    DateTime value, {
    required DateTime now,
    bool withTime = false,
  }) {
    final age = _daysBetween(_day(value), _day(now));
    final time = withTime ? ', ${DateFormatter.time(value)}' : '';
    if (age == 0) return '${labels.today}$time';
    if (age == 1) return '${labels.yesterday}$time';
    if (age > 1 && age <= 7) {
      final short = DateFormatter.date(value).substring(0, 6);
      return '${labels.weekdayShort(value)} $short';
    }
    return DateFormatter.date(value);
  }

  /// Fälligkeit relativ zu [now].
  static DueLabel due(
    RelativeDateLabels labels,
    DateTime dueDate, {
    required DateTime now,
  }) {
    final days = _daysBetween(_day(now), _day(dueDate));
    if (days == 0) return DueLabel(labels.dueToday, DueState.today);
    if (days > 0) return DueLabel(labels.dueIn(days), DueState.upcoming);
    return DueLabel(labels.overdueSince(-days), DueState.overdue);
  }
}
