import 'package:material_ui/material_ui.dart';

/// Datum und Uhrzeit mit den Auswahldialogen der Plattform. Liefert `null`,
/// wenn abgebrochen wurde.
Future<DateTime?> pickDateTime(
  BuildContext context, {
  required DateTime initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate ?? DateTime(initial.year - 1),
    lastDate: lastDate ?? DateTime(initial.year + 2),
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
