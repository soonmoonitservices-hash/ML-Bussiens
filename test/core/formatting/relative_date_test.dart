import 'package:flutter_test/flutter_test.dart';
import 'package:warenbestand/core/formatting/relative_date.dart';

void main() {
  final labels = RelativeDateLabels(
    today: 'Heute',
    yesterday: 'Gestern',
    weekdayShort: (date) => 'Mo.',
    dueToday: 'heute fällig',
    dueIn: (days) => 'fällig in $days Tagen',
    overdueSince: (days) => 'seit $days Tagen überfällig',
  );
  final now = DateTime(2026, 11, 20, 12);

  test('Heute mit Uhrzeit', () {
    expect(
      RelativeDate.format(
        labels,
        DateTime(2026, 11, 20, 8, 30),
        now: now,
        withTime: true,
      ),
      'Heute, 08:30',
    );
  });

  test('Gestern, Wochentag, älter als 7 Tage', () {
    expect(
      RelativeDate.format(labels, DateTime(2026, 11, 19), now: now),
      'Gestern',
    );
    expect(
      RelativeDate.format(labels, DateTime(2026, 11, 16), now: now),
      'Mo. 16.11.',
    );
    expect(
      RelativeDate.format(labels, DateTime(2026, 11), now: now),
      '01.11.2026',
    );
  });

  test('Fälligkeit: in Tagen, heute, überfällig', () {
    final inThree = RelativeDate.due(labels, DateTime(2026, 11, 23), now: now);
    expect(inThree.text, 'fällig in 3 Tagen');
    expect(inThree.state, DueState.upcoming);
    expect(
      RelativeDate.due(labels, DateTime(2026, 11, 20), now: now).state,
      DueState.today,
    );
    final late = RelativeDate.due(labels, DateTime(2026, 11, 18), now: now);
    expect(late.text, 'seit 2 Tagen überfällig');
    expect(late.state, DueState.overdue);
  });
}
