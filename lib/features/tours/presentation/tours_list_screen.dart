import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/relative_date.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/tours/data/tour_goods_documents.dart';
import 'package:warenbestand/features/tours/data/tours_repository.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/features/tours/presentation/tour_status_label.dart';
import 'package:warenbestand/l10n/date_labels.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/money_text.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/selection/list_selection.dart';

/// Tourliste mit Filter Unterwegs, Geplant, Abgeschlossen und Suche.
class ToursListScreen extends ConsumerStatefulWidget {
  const ToursListScreen({super.key});

  @override
  ConsumerState<ToursListScreen> createState() => _ToursListScreenState();
}

class _ToursListScreenState extends ConsumerState<ToursListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _tours = <Tour>[];
  final _selection = ListSelection<Tour>();
  Timer? _debounce;
  bool _busy = false;
  TourStatus _status = TourStatus.active;
  AppError? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _selection.addListener(_rebuild);
    unawaited(_load(reset: true));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    _selection
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

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
        .read(toursRepositoryProvider)
        .list(page: nextPage, status: _status, search: _search.text);
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _tours.clear();
          _tours.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == ToursRepository.pageSize;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _deleteSelected() async {
    final strings = AppLocalizations.of(context);
    final chosen = _selection.values;
    if (!await confirmDeleteMany(context, chosen.length) || !mounted) return;
    setState(() => _busy = true);
    final repository = ref.read(toursRepositoryProvider);
    var failed = 0;
    for (final tour in chosen) {
      if (await repository.deleteDraft(tour.id) is Failure) failed++;
    }
    if (!mounted) return;
    _selection.clear();
    setState(() => _busy = false);
    if (failed == 0) {
      showSuccessSnack(context, strings.deletedMany(chosen.length));
    } else {
      showErrorSnack(context, strings.deleteManyFailed(failed));
    }
    await _load(reset: true);
  }

  Future<void> _shareSelected() async {
    final strings = AppLocalizations.of(context);
    final closed = _selection.values
        .where((tour) => tour.status == TourStatus.closed)
        .toList();
    if (closed.isEmpty) {
      showErrorSnack(context, strings.nothingToShare);
      return;
    }
    setState(() => _busy = true);
    final repository = ref.read(toursRepositoryProvider);
    final documents = ref.read(tourGoodsDocumentsProvider);
    final files = <PdfShareFile>[];
    for (final tour in closed) {
      final items = await repository.items(tour.id);
      final expenses = await repository.expenses(tour.id);
      if (items is! Success<List<TourItem>> ||
          expenses is! Success<List<TourExpense>>) {
        continue;
      }
      final pdf = await documents.summary(
        tour: tour,
        items: items.value,
        expenses: expenses.value,
      );
      if (pdf case Success(:final value)) {
        files.add((
          name: TourGoodsDocuments.summaryFileName(tour.number ?? ''),
          bytes: value,
        ));
      }
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (files.isEmpty) {
      showErrorSnack(context, strings.nothingToShare);
      return;
    }
    await sharePdfFiles(files);
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
      title: strings.tours,
      controller: _scroll,
      onRefresh: () => _load(reset: true),
      showBack: false,
      actions: [
        if (_tours.isNotEmpty)
          TextButton(
            onPressed: _selection.toggleMode,
            child: Text(_selection.active ? strings.done : strings.select),
          ),
        IconButton(
          tooltip: strings.planTour,
          onPressed: () => _open('/tours/new'),
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
                hint: strings.toursSearch,
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilterBar<TourStatus>(
                selected: _status,
                onSelected: (value) {
                  setState(() => _status = value);
                  unawaited(_load(reset: true));
                },
                options: [
                  (value: TourStatus.active, label: strings.tourStatusActive),
                  (value: TourStatus.draft, label: strings.tourStatusDraft),
                  (value: TourStatus.closed, label: strings.tourStatusClosed),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selection.active && _tours.isNotEmpty)
                SelectionToolbar(
                  count: _selection.count,
                  busy: _busy,
                  allSelected: _selection.allSelected(_tours.map((t) => t.id)),
                  onToggleAll: () => _selection.toggleAll({
                    for (final tour in _tours) tour.id: tour,
                  }),
                  onShare: _shareSelected,
                  onDelete: _deleteSelected,
                ),
              if (_error != null) ...[
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
                TextButton(
                  onPressed: () => _load(reset: true),
                  child: Text(strings.retry),
                ),
              ] else if (_tours.isEmpty && !_loading)
                EmptyState(
                  message: searching ? strings.noResults : strings.noTours,
                  actionLabel: searching ? null : strings.planTour,
                  onAction: () => _open('/tours/new'),
                )
              else
                ...AppListRow.divided([
                  for (final tour in _tours) _row(strings, tour),
                ]),
              if (_loading) const SkeletonList(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations strings, Tour tour) {
    final difference = tour.difference;
    final Widget value;
    if (tour.status == TourStatus.closed && difference != null) {
      value = difference.isZero
          ? const Icon(
              AppIcons.success,
              size: AppIcons.size,
              color: AppColors.success,
            )
          : MoneyText(
              difference,
              signed: true,
              color: difference.isNegative
                  ? AppColors.error
                  : AppColors.success,
            );
    } else {
      value = MoneyText(tour.loadedValueSell);
    }
    final selecting = _selection.active;
    return AppListRow(
      icon: AppIcons.tour,
      leading: selecting
          ? Checkbox(
              value: _selection.isSelected(tour.id),
              onChanged: (_) => _selection.toggle(tour.id, tour),
              visualDensity: VisualDensity.compact,
            )
          : null,
      title: tour.title,
      subtitle: [
        if (tour.number != null) tour.number!,
        tour.driverName,
        RelativeDate.format(
          AppLocalizations.of(context).dateLabels,
          tour.plannedAt,
          now: DateTime.now(),
          withTime: true,
        ),
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          value,
          const SizedBox(height: AppSpacing.xxs),
          TourStatusLabel(tour.status),
        ],
      ),
      showChevron: !selecting,
      onTap: selecting
          ? () => _selection.toggle(tour.id, tour)
          : () => _open('/tours/${tour.id}'),
    );
  }
}
