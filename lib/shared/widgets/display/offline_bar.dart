import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/network/connectivity_provider.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Schmale Leiste oben, solange keine Internetverbindung besteht.
class OfflineBar extends ConsumerWidget {
  const OfflineBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;
    if (online) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.warningSurface,
      padding: EdgeInsetsDirectional.only(
        top: MediaQuery.paddingOf(context).top + AppSpacing.xxs,
        bottom: AppSpacing.xxs,
        start: AppSpacing.page,
        end: AppSpacing.page,
      ),
      child: Row(
        children: [
          const Icon(AppIcons.warning, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppLocalizations.of(context).noConnection,
              style: AppText.chip.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
