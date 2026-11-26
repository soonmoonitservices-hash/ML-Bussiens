import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Abschnittsüberschrift (17) mit Abstand nach oben, optional mit Aktion am Ende.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: AppSpacing.lg,
      bottom: AppSpacing.xs,
      start: AppSpacing.xs,
      end: AppSpacing.xs,
    ),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppText.section)),
        ?trailing,
      ],
    ),
  );
}
