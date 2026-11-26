import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Kurze Anleitungen zu den wichtigsten Abläufen.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final topics = [
      (strings.helpTourTitle, strings.helpTourText),
      (strings.helpStockTitle, strings.helpStockText),
      (strings.helpDocsTitle, strings.helpDocsText),
      (strings.helpExpensesTitle, strings.helpExpensesText),
    ];
    return AppScreen(
      title: strings.help,
      children: [
        for (final topic in topics) ...[
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: AppSpacing.lg,
              bottom: AppSpacing.xs,
            ),
            child: Text(topic.$1, style: AppText.section),
          ),
          Text(topic.$2, style: AppText.body),
        ],
      ],
    );
  }
}
