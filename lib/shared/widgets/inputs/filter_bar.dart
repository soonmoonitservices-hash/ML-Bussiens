import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/feedback/haptics.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Filterleiste: graue Fläche, das aktive Segment ist weiß mit schwarzer
/// Schrift. Bei Platzmangel (große Schrift) brechen die Segmente um.
class FilterBar<T> extends StatelessWidget {
  const FilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xxs),
    decoration: BoxDecoration(
      color: AppColors.paperMuted,
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
    child: Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (final option in options)
          _Segment(
            label: option.label,
            selected: option.value == selected,
            onTap: () {
              Haptics.select();
              onSelected(option.value);
            },
          ),
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: Material(
      color: selected ? AppColors.paper : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.control - 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control - 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40, minWidth: 48),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: AppText.chip.copyWith(
                  color: selected ? AppColors.ink : AppColors.inkMuted,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
