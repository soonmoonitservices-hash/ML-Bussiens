import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';

/// Leerzustand: ein kurzer Satz, optional eine Aktion. Linksbündig, keine
/// Illustration.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.lg,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: AppText.body.copyWith(color: AppColors.inkMuted)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    ),
  );
}
