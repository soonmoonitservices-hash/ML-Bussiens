import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/auth/domain/app_profile.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Benutzerliste für den Chef: Rolle ändern, sperren, wieder freigeben.
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<AppProfile>? _users;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await ref.read(usersRepositoryProvider).list();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _users = value;
          _error = null;
        });
      case Failure(:final error):
        setState(() => _error = error);
    }
  }

  Future<void> _edit(AppProfile user) async {
    final strings = AppLocalizations.of(context);
    final choice = await showPickSheet<String>(
      context,
      title: user.name,
      searchable: false,
      loader: (_) async => [
        PickOption(
          value: user.isChef ? 'office' : 'chef',
          title: user.isChef ? strings.makeOffice : strings.makeChef,
        ),
        PickOption(
          value: 'toggle',
          title: user.active ? strings.deactivate : strings.reactivate,
        ),
      ],
    );
    if (choice == null || !mounted) return;
    final repository = ref.read(usersRepositoryProvider);
    final result = choice == 'toggle'
        ? await repository.update(user.id, active: !user.active)
        : await repository.update(user.id, role: choice);
    if (!mounted) return;
    if (result case Failure(:final error)) setState(() => _error = error);
    await _load();
  }

  Future<void> _createUser() async {
    await context.push<void>('/users/new');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final users = _users;
    final selfId = ref.watch(sessionControllerProvider).profile?.id;
    return AppScreen(
      title: strings.users,
      onRefresh: _load,
      actions: [
        IconButton(
          tooltip: strings.newUser,
          onPressed: _createUser,
          icon: const Icon(AppIcons.add),
        ),
      ],
      children: [
        Text(strings.usersHint, style: AppText.label),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (users == null && _error == null)
          const SkeletonList()
        else if (users != null)
          ...AppListRow.divided([
            for (final user in users)
              AppListRow(
                title: user.name,
                subtitle:
                    '${user.email} · '
                    '${user.isChef ? strings.roleChef : strings.roleOffice}',
                trailing: user.active
                    ? null
                    : StatusLabel(
                        strings.inactive,
                        color: AppColors.error,
                        surface: AppColors.errorSurface,
                      ),
                onTap: user.id == selfId ? null : () => _edit(user),
              ),
          ]),
      ],
    );
  }
}
