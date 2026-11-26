import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';

void main() {
  group('ReportPeriod.of', () {
    test('Monat: 1. bis letzter Tag', () {
      final period = ReportPeriod.of(ReportRange.month, DateTime(2026, 11, 16));
      expect(period.from, DateTime(2026, 11));
      expect(period.to, DateTime(2026, 11, 30));
      expect(period.days, 30);
    });

    test('Februar im Schaltjahr hat 29 Tage', () {
      final period = ReportPeriod.of(ReportRange.month, DateTime(2028, 2, 10));
      expect(period.to, DateTime(2028, 2, 29));
    });

    test('Woche: Montag bis Sonntag (16.11.2026 ist ein Montag)', () {
      final period = ReportPeriod.of(ReportRange.week, DateTime(2026, 11, 19));
      expect(period.from, DateTime(2026, 11, 16));
      expect(period.to, DateTime(2026, 11, 22));
    });

    test('Woche über den Monatswechsel', () {
      final period = ReportPeriod.of(ReportRange.week, DateTime(2026, 12, 2));
      expect(period.from, DateTime(2026, 11, 30));
      expect(period.to, DateTime(2026, 12, 6));
    });

    test('Jahr und Tag', () {
      final year = ReportPeriod.of(ReportRange.year, DateTime(2026, 6));
      expect(year.from, DateTime(2026));
      expect(year.to, DateTime(2026, 12, 31));
      final day = ReportPeriod.of(ReportRange.day, DateTime(2026, 6, 1, 15));
      expect(day.from, day.to);
      expect(day.days, 1);
    });
  });

  group('Vorzeitraum und Verschieben', () {
    test('Vormonat und Vorjahr', () {
      final month = ReportPeriod.of(ReportRange.month, DateTime(2026, 1, 15));
      final previous = month.previous(ReportRange.month);
      expect(previous.from, DateTime(2025, 12));
      expect(previous.to, DateTime(2025, 12, 31));
      final year = ReportPeriod.of(ReportRange.year, DateTime(2026, 5));
      expect(year.previous(ReportRange.year).from, DateTime(2025));
    });

    test('Woche: die Woche davor', () {
      final week = ReportPeriod.of(ReportRange.week, DateTime(2026, 11, 16));
      final previous = week.previous(ReportRange.week);
      expect(previous.from, DateTime(2026, 11, 9));
      expect(previous.to, DateTime(2026, 11, 15));
    });

    test('Eigener Zeitraum: gleich lang direkt davor', () {
      final custom = ReportPeriod(
        from: DateTime(2026, 11, 10),
        to: DateTime(2026, 11, 14),
      );
      final previous = custom.previous(ReportRange.custom);
      expect(previous.from, DateTime(2026, 11, 5));
      expect(previous.to, DateTime(2026, 11, 9));
    });

    test('Verschieben über den Jahreswechsel', () {
      final month = ReportPeriod.of(ReportRange.month, DateTime(2026, 12, 5));
      expect(month.shifted(ReportRange.month, 1).from, DateTime(2027));
      expect(month.shifted(ReportRange.month, -12).from, DateTime(2025, 12));
    });
  });

  group('Körnung und Kalenderwoche', () {
    test('Körnung passt zur Länge', () {
      expect(
        ReportPeriod.of(ReportRange.month, DateTime(2026, 11)).granularity,
        ReportGranularity.day,
      );
      expect(
        ReportPeriod.of(ReportRange.year, DateTime(2026)).granularity,
        ReportGranularity.month,
      );
      expect(
        ReportPeriod(from: DateTime(2026), to: DateTime(2026, 5)).granularity,
        ReportGranularity.week,
      );
    });

    test('ISO-Kalenderwoche: 16.11.2026 ist KW 47', () {
      expect(
        ReportPeriod.of(ReportRange.week, DateTime(2026, 11, 16)).isoWeek,
        47,
      );
      expect(ReportPeriod.of(ReportRange.week, DateTime(2026)).isoWeek, 1);
    });
  });

  group('changePercent', () {
    test('+12 % bei 1.120 € gegen 1.000 €', () {
      expect(
        changePercent(
          current: const Money(112000),
          previous: const Money(100000),
        ),
        12,
      );
    });

    test('negativ und gerundet: 960 € gegen 1.000 € = −4 %', () {
      expect(
        changePercent(
          current: const Money(96000),
          previous: const Money(100000),
        ),
        -4,
      );
      expect(
        changePercent(
          current: const Money(100050),
          previous: const Money(100000),
        ),
        0,
      );
    });

    test('kein Vergleich, wenn der Vorzeitraum 0 war', () {
      expect(
        changePercent(current: const Money(5000), previous: Money.zero),
        isNull,
      );
    });
  });
}
