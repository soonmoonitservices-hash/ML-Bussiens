import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Karte: weiß, 1 px Rahmen, kein Schatten. Mit [dark] schwarze Fläche mit
/// weißer Schrift (nur für den Blickfang auf der Startseite).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.dark = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.surface);
    return Material(
      color: dark ? AppColors.ink : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: dark ? BorderSide.none : const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
