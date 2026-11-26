import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final session = ref.watch(sessionControllerProvider);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final rows = <(String, IconData, String)>[
          (strings.products, AppIcons.stock, '/products'),
          (strings.reports, AppIcons.report, '/reports'),
          (strings.expenses, AppIcons.expense, '/expenses'),
          (strings.drivers, AppIcons.driver, '/drivers'),
          if (session.canManage) (strings.users, AppIcons.users, '/users'),
          if (session.canManage)
            (strings.company, AppIcons.company, '/company'),
          if (session.isSuperadmin)
            (strings.platform, AppIcons.company, '/platform'),
          (strings.account, AppIcons.user, '/account'),
          (strings.help, AppIcons.help, '/help'),
        ];
        final notice = GoRouterState.of(context).uri.queryParameters['notice'];
        return AppScreen(
          title: strings.more,
          children: [
            if (notice == 'access')
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppSpacing.sm,
                ),
                child: NoticeBanner(
                  message: strings.accessDenied,
                  kind: NoticeKind.warning,
                ),
              ),
            ...AppListRow.divided([
              for (final row in rows)
                AppListRow(
                  title: row.$1,
                  icon: row.$2,
                  showChevron: true,
                  onTap: () => context.push(row.$3),
                ),
            ]),
          ],
        );
      },
    );
  }
}
