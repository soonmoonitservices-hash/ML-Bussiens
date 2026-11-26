import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Bestätigungsdialog im Stil der Plattform. Liefert `true` bei Bestätigung.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String? confirmLabel,
  String? title,
}) async {
  final strings = AppLocalizations.of(context);
  final result = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: title == null ? null : Text(title),
      content: SingleChildScrollView(child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? strings.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
