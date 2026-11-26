import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/feedback/haptics.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Erfolgsmeldung: dunkle Leiste unten mit grünem Häkchen.
void showSuccessSnack(BuildContext context, String message) {
  Haptics.success();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.success,
              size: AppIcons.size,
              color: AppColors.successOnInk,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

/// Fehler- oder Hinweismeldung: dunkle Leiste unten mit rotem Symbol.
void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.error,
              size: AppIcons.size,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
