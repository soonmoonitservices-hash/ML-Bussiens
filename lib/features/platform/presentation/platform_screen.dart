import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/platform/domain/platform_tenant.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Nur für den Superadmin: Firmen mit ihrem Chef. Chef anlegen, Firma sperren
/// oder endgültig löschen.
class PlatformScreen extends ConsumerStatefulWidget {
  const PlatformScreen({super.key});

  @override
  ConsumerState<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends ConsumerState<PlatformScreen> {
  List<PlatformTenant>? _tenants;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await ref.read(platformRepositoryProvider).tenants();
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _tenants = value;
          _error = null;
        });
      case Failure(:final error):
        setState(() => _error = error);
    }
  }

  Future<void> _createCompany() async {
    await context.push<void>('/users/new?company=1');
    if (mounted) await _load();
  }

  Future<void> _manage(PlatformTenant tenant) async {
    final strings = AppLocalizations.of(context);
    final choice = await showPickSheet<String>(
      context,
      title: tenant.name,
      searchable: false,
      loader: (_) async => [
        PickOption(
          value: 'block',
          title: tenant.blocked ? strings.unblockFirm : strings.blockFirm,
        ),
        PickOption(value: 'delete', title: strings.deleteFirm),
      ],
    );
    if (choice == null || !mounted) return;
    if (choice == 'block') {
      final result = await ref
          .read(platformRepositoryProvider)
          .setBlocked(tenant.id, blocked: !tenant.blocked);
      if (!mounted) return;
      if (result case Failure(:final error)) setState(() => _error = error);
      await _load();
    } else {
      await _delete(tenant);
    }
  }

  Future<void> _delete(PlatformTenant tenant) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(name: tenant.name),
    );
    if (confirmed != true || !mounted) return;
    final result = await ref
        .read(platformRepositoryProvider)
        .deleteFirm(tenant.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        showSuccessSnack(context, strings.firmDeleted);
      case Failure(:final error):
        setState(() => _error = error);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final tenants = _tenants;
    return AppScreen(
      title: strings.platform,
      onRefresh: _load,
      actions: [
        IconButton(
          tooltip: strings.userNewCompany,
          onPressed: _createCompany,
          icon: const Icon(AppIcons.add),
        ),
      ],
      children: [
        Text(strings.platformHint, style: AppText.label),
        const SizedBox(height: AppSpacing.md),
        if (_error != null) ...[
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (tenants == null && _error == null)
          const SkeletonList()
        else if (tenants != null && tenants.isEmpty)
          EmptyState(
            message: strings.noFirms,
            actionLabel: strings.userNewCompany,
            onAction: _createCompany,
          )
        else if (tenants != null)
          ...AppListRow.divided([
            for (final tenant in tenants)
              AppListRow(
                key: ValueKey(tenant.id),
                icon: AppIcons.company,
                title: tenant.name,
                subtitle: [
                  if (tenant.chefName != null) tenant.chefName!,
                  if (tenant.chefEmail != null) tenant.chefEmail!,
                  strings.usersCount(tenant.userCount),
                ].join(' · '),
                trailing: tenant.blocked
                    ? StatusLabel(
                        strings.firmBlocked,
                        color: AppColors.error,
                        surface: AppColors.errorSurface,
                      )
                    : null,
                showChevron: true,
                onTap: () => _manage(tenant),
              ),
          ]),
      ],
    );
  }
}

/// Bestätigung für das endgültige Löschen: Der Firmenname muss eingetippt werden.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.name});

  final String name;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final matches = _controller.text.trim() == widget.name.trim();
    return AlertDialog(
      title: Text(strings.deleteFirm),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.deleteFirmMessage(widget.name)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autocorrect: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: strings.typeNameToConfirm),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: matches ? () => Navigator.pop(context, true) : null,
          child: Text(strings.deleteFirmConfirm),
        ),
      ],
    );
  }
}
