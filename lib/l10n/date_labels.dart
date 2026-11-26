import 'package:intl/intl.dart' show DateFormat;
import 'package:warenbestand/core/formatting/relative_date.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Wörter für relative Datumsangaben aus den ARB-Dateien.
extension DateLabels on AppLocalizations {
  RelativeDateLabels get dateLabels => RelativeDateLabels(
    today: today,
    yesterday: yesterday,
    weekdayShort: (date) => DateFormat.E(localeName).format(date),
    dueToday: dueToday,
    dueIn: dueInDays,
    overdueSince: overdueSinceDays,
  );
}
