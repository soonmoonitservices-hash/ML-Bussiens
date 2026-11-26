import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/shared/widgets/buttons/press_scale.dart';

/// Hauptaktion: dunkle Fläche, volle Breite, Ecken 12. Steht am Ende des
/// Inhalts, nie klebend.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Zeigt einen Ladekreis und sperrt den Button.
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => PressScale(
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.paper,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIcons.size),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(child: Text(label, textAlign: TextAlign.center)),
              ],
            ),
    ),
  );
}
