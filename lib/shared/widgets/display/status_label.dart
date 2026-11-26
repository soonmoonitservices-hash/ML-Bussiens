import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Statuswort in Statusfarbe auf heller Fläche (z. B. „Inaktiv“, „Überfällig“).
/// Als Pille.
class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {this.color, this.surface, super.key});

  final String text;

  /// Textfarbe; ohne Angabe gedämpftes Grau.
  final Color? color;
  final Color? surface;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: surface ?? AppColors.paperMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      text,
      style: AppText.chip.copyWith(color: color ?? AppColors.ink),
    ),
  );
}
