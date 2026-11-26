import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';

/// Text des Tourstatus in der Sprache der App.
String tourStatusText(AppLocalizations strings, TourStatus status) =>
    switch (status) {
      TourStatus.draft => strings.tourStatusDraft,
      TourStatus.active => strings.tourStatusActive,
      TourStatus.closed => strings.tourStatusClosed,
    };

/// Statuswort einer Tour: Entwurf in Warnfarbe, sonst grau.
class TourStatusLabel extends StatelessWidget {
  const TourStatusLabel(this.status, {super.key});

  final TourStatus status;

  @override
  Widget build(BuildContext context) {
    final text = tourStatusText(AppLocalizations.of(context), status);
    return status == TourStatus.draft
        ? StatusLabel(
            text,
            color: AppColors.warning,
            surface: AppColors.warningSurface,
          )
        : StatusLabel(text);
  }
}
