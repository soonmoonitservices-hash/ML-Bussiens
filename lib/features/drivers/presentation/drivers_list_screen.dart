import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/drivers/data/drivers_repository.dart';
import 'package:warenbestand/features/drivers/domain/driver.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

class DriversListScreen extends ConsumerStatefulWidget {
  const DriversListScreen({super.key});

  @override
  ConsumerState<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends ConsumerState<DriversListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _drivers = <Driver>[];
  Timer? _debounce;
  AppError? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) unawaited(_load());
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _load(reset: true),
    );
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final nextPage = reset ? 0 : _page;
    final result = await ref
        .read(driversRepositoryProvider)
        .list(page: nextPage, search: _search.text);
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _drivers.clear();
          _drivers.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == DriversRepository.pageSize;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final searching = _search.text.trim().isNotEmpty;
    return AppScreen.slivers(
      title: strings.drivers,
      controller: _scroll,
      onRefresh: () => _load(reset: true),
      actions: [
        IconButton(
          tooltip: strings.newDriver,
          onPressed: () => _open('/drivers/new'),
          icon: const Icon(AppIcons.add),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          sliver: SliverList.list(
            children: [
              AppSearchField(
                controller: _search,
                hint: strings.search,
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_error != null) ...[
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
                TextButton(
                  onPressed: () => _load(reset: true),
                  child: Text(strings.retry),
                ),
              ] else if (_drivers.isEmpty && !_loading)
                EmptyState(
                  message: searching ? strings.noResults : strings.noDrivers,
                  actionLabel: searching ? null : strings.newDriver,
                  onAction: () => _open('/drivers/new'),
                )
              else
                ...AppListRow.divided([
                  for (final driver in _drivers)
                    AppListRow(
                      title: driver.name,
                      subtitle: [driver.phone, driver.vehicle]
                          .whereType<String>()
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                      trailing: driver.active
                          ? null
                          : StatusLabel(strings.inactive),
                      showChevron: true,
                      onTap: () => _open('/drivers/${driver.id}'),
                    ),
                ]),
              if (_loading) const SkeletonList(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}
