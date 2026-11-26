import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Zeile einer Liste: Icon, Titel, Nebentext, Wert am Ende. Getrennt durch
/// Linien (siehe [AppListRow.divided]), keine Karten.
class AppListRow extends StatelessWidget {
  const AppListRow({
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Eigenes Element vorn (z. B. Auswahlfeld); ersetzt [icon].
  final Widget? leading;

  /// Wert oder Status am Ende (rechtsbündig in LTR).
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Pfeil „weiter“ am Ende.
  final bool showChevron;

  /// Mehrere Zeilen mit Trennlinien dazwischen.
  static List<Widget> divided(List<Widget> rows) => [
    for (var i = 0; i < rows.length; i++) ...[
      rows[i],
      if (i < rows.length - 1) const Divider(),
    ],
  ];

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ] else if (icon != null) ...[
              Icon(icon, size: AppIcons.size),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.body),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!, style: AppText.label),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.forward(context),
                size: 18,
                color: AppColors.inkFaint,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
