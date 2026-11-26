import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';

/// Hinweis oben im Formular: Der angefangene Stand wurde wiederhergestellt.
/// „Verwerfen“ fragt nach und ruft dann [onDiscard] auf (leeres Formular).
class DraftRestoredBanner extends StatelessWidget {
  const DraftRestoredBanner({required this.onDiscard, super.key});

  final VoidCallback onDiscard;

  Future<void> _confirm(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: strings.discardChangesTitle,
      message: strings.discardChangesMessage,
      confirmLabel: strings.discard,
    );
    if (discard) onDiscard();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NoticeBanner(
            message: strings.draftRestored,
            kind: NoticeKind.warning,
          ),
          TextButton(
            onPressed: () => _confirm(context),
            child: Text(strings.discard),
          ),
        ],
      ),
    );
  }
}
