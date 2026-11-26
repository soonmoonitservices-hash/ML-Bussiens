import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Beschriftung links, Wert am Zeilenende (Preise, Summen, Stammdaten).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.strong = false,
    super.key,
  });

  final String label;
  final String value;
  final Color? valueColor;

  /// Wert und Beschriftung fett (Endsummen).
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: strong ? AppText.bodyStrong : AppText.body),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            textDirection: TextDirection.ltr,
            style: AppText.amount.copyWith(
              color: valueColor,
              fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
