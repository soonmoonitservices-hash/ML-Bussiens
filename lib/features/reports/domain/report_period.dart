import 'package:warenbestand/core/value_objects/money.dart';

/// Art des Zeitraums in der Auswertung.
enum ReportRange { day, week, month, year, custom }

/// Körnung der Zeitreihe (wie `p_granularity` in der Datenbank).
enum ReportGranularity {
  day('day'),
  week('week'),
  month('month');

  const ReportGranularity(this.dbValue);

  final String dbValue;
}

/// Ein Zeitraum von [from] bis [to] (beide Tage eingeschlossen).
final class ReportPeriod {
  const ReportPeriod({required this.from, required this.to});

  /// Zeitraum der Art [range], der den Tag [anchor] enthält. Woche = Montag
  /// bis Sonntag.
  factory ReportPeriod.of(ReportRange range, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    switch (range) {
      case ReportRange.day:
      case ReportRange.custom:
        return ReportPeriod(from: day, to: day);
      case ReportRange.week:
        final monday = day.subtract(Duration(days: day.weekday - 1));
        return ReportPeriod(
          from: monday,
          to: DateTime(monday.year, monday.month, monday.day + 6),
        );
      case ReportRange.month:
        return ReportPeriod(
          from: DateTime(day.year, day.month),
          to: DateTime(day.year, day.month + 1, 0),
        );
      case ReportRange.year:
        return ReportPeriod(
          from: DateTime(day.year),
          to: DateTime(day.year, 12, 31),
        );
    }
  }

  final DateTime from;
  final DateTime to;

  /// Anzahl der Tage im Zeitraum.
  int get days =>
      DateTime.utc(
        to.year,
        to.month,
        to.day,
      ).difference(DateTime.utc(from.year, from.month, from.day)).inDays +
      1;

  /// Der gleich lange Zeitraum davor (für den Vergleich). Bei Monat und Jahr
  /// der Vormonat bzw. das Vorjahr, sonst direkt davor.
  ReportPeriod previous(ReportRange range) {
    switch (range) {
      case ReportRange.month:
        return ReportPeriod.of(
          ReportRange.month,
          DateTime(from.year, from.month - 1),
        );
      case ReportRange.year:
        return ReportPeriod.of(ReportRange.year, DateTime(from.year - 1));
      case ReportRange.day:
      case ReportRange.week:
      case ReportRange.custom:
        final length = days;
        final end = DateTime(from.year, from.month, from.day - 1);
        return ReportPeriod(
          from: DateTime(end.year, end.month, end.day - length + 1),
          to: end,
        );
    }
  }

  /// Der Zeitraum eine Einheit weiter (negativ = zurück). Eigene Zeiträume
  /// werden um ihre Länge verschoben.
  ReportPeriod shifted(ReportRange range, int steps) {
    switch (range) {
      case ReportRange.day:
        return ReportPeriod.of(
          range,
          DateTime(from.year, from.month, from.day + steps),
        );
      case ReportRange.week:
        return ReportPeriod.of(
          range,
          DateTime(from.year, from.month, from.day + 7 * steps),
        );
      case ReportRange.month:
        return ReportPeriod.of(range, DateTime(from.year, from.month + steps));
      case ReportRange.year:
        return ReportPeriod.of(range, DateTime(from.year + steps));
      case ReportRange.custom:
        final length = days;
        final start = DateTime(
          from.year,
          from.month,
          from.day + length * steps,
        );
        return ReportPeriod(
          from: start,
          to: DateTime(start.year, start.month, start.day + length - 1),
        );
    }
  }

  /// Körnung der Zeitreihe, die zur Länge des Zeitraums passt.
  ReportGranularity get granularity => days <= 62
      ? ReportGranularity.day
      : days <= 200
      ? ReportGranularity.week
      : ReportGranularity.month;

  /// ISO-Kalenderwoche des Montags dieses Zeitraums (für die Anzeige).
  int get isoWeek {
    final thursday = from.add(Duration(days: 4 - from.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(
      Duration(days: firstThursday.weekday - 1),
    );
    final weekStart = thursday.subtract(Duration(days: thursday.weekday - 1));
    return 1 + weekStart.difference(firstWeekStart).inDays ~/ 7;
  }
}

/// Veränderung zum Vorzeitraum in ganzen Prozent, kaufmännisch gerundet.
/// `null`, wenn der Vorzeitraum 0 war (kein sinnvoller Vergleich).
int? changePercent({required Money current, required Money previous}) {
  if (previous.isZero) return null;
  return roundHalfAwayFromZero(
    (current.cents - previous.cents) * 100,
    previous.cents.abs(),
  );
}
