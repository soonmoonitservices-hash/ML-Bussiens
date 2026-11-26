import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/feedback/haptics.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Auswahl aus wenigen Werten (Filter, Einheit, Steuersatz). Pillen:
/// gewählt schwarz, sonst hellgrau. Bricht bei Platzmangel in die nächste Zeile
/// um, scrollt also nie waagerecht und läuft nie über.
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<({T value, String label})> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final option in options)
        _Chip(
          label: option.label,
          selected: option.value == selected,
          onTap: () {
            Haptics.select();
            onSelected(option.value);
          },
        ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
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
      color: selected ? AppColors.ink : AppColors.paperMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
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
                  color: selected ? AppColors.paper : AppColors.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
