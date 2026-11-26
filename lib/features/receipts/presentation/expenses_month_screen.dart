import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/receipts/data/expense_documents.dart';
import 'package:warenbestand/features/receipts/data/expenses_repository.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/features/receipts/presentation/expense_category_label.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/money_text.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/selection/list_selection.dart';

/// Ausgaben nach Monaten („Monatsordner“) mit Summe, Filter und Sammel-PDF.
class ExpensesMonthScreen extends ConsumerStatefulWidget {
  const ExpensesMonthScreen({super.key});

  @override
  ConsumerState<ExpensesMonthScreen> createState() =>
      _ExpensesMonthScreenState();
}

class _ExpensesMonthScreenState extends ConsumerState<ExpensesMonthScreen> {
  final _scroll = ScrollController();
  final _expenses = <Expense>[];
  final _selected = <String, Expense>{};
  bool _selecting = false;
  late int _year;
  late int _month;
  ExpenseFilter _filter = ExpenseFilter.all;
  MonthSummary _summary = MonthSummary.empty;
  AppError? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    _scroll.addListener(_onScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) unawaited(_load());
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_year, _month + delta);
    setState(() {
      _year = next.year;
      _month = next.month;
    });
    unawaited(_reload());
  }

  Future<void> _reload() async {
    unawaited(_loadSummary());
    await _load(reset: true);
  }

  Future<void> _loadSummary() async {
    final result = await ref
        .read(expensesRepositoryProvider)
        .summary(_year, _month);
    if (!mounted) return;
    if (result case Success(:final value)) setState(() => _summary = value);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final nextPage = reset ? 0 : _page;
    final result = await ref
        .read(expensesRepositoryProvider)
        .month(year: _year, month: _month, filter: _filter, page: nextPage);
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _expenses.clear();
          _expenses.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == ExpensesRepository.pageSize;
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
    if (mounted) await _reload();
  }

  void _toggleSelecting() => setState(() {
    _selecting = !_selecting;
    if (!_selecting) _selected.clear();
  });

  void _toggle(Expense expense) => setState(() {
    if (_selected.containsKey(expense.id)) {
      _selected.remove(expense.id);
    } else {
      _selected[expense.id] = expense;
    }
  });

  void _toggleAll() => setState(() {
    final allSelected = _expenses.every((e) => _selected.containsKey(e.id));
    for (final expense in _expenses) {
      if (allSelected) {
        _selected.remove(expense.id);
      } else {
        _selected[expense.id] = expense;
      }
    }
  });

  /// Die gewählten Ausgaben löschen (nach Rückfrage); eine oder alle.
  Future<void> _deleteSelected() async {
    final strings = AppLocalizations.of(context);
    final chosen = _selected.values.toList();
    if (chosen.isEmpty) return;
    if (!await confirmDeleteMany(context, chosen.length) || !mounted) return;
    final repository = ref.read(expensesRepositoryProvider);
    var failed = 0;
    for (final expense in chosen) {
      if (await repository.delete(expense.id) is Failure) failed++;
    }
    if (!mounted) return;
    setState(_selected.clear);
    if (failed == 0) {
      showSuccessSnack(context, strings.deletedMany(chosen.length));
    } else {
      showErrorSnack(context, strings.deleteManyFailed(failed));
    }
    await _reload();
  }

  /// Die gewählten Belege als EIN PDF zum Teilen (z. B. an den Steuerberater).
  Future<void> _exportSelection() async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(expenseDocumentsProvider);
    final chosen = _selected.values.toList();
    if (chosen.isEmpty) return;
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.exportSelectionPdf,
        fileName: ExpenseDocuments.selectionFileName(chosen),
        load: () => documents.selection(chosen),
      ),
    );
  }

  Future<void> _exportPdf() async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(expenseDocumentsProvider);
    final year = _year;
    final month = _month;
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.exportMonthPdf,
        fileName: ExpenseDocuments.monthFileName(year, month),
        load: () => documents.month(year, month),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final monthName = DateFormat.yMMMM(locale).format(DateTime(_year, _month));
    return AppScreen.slivers(
      title: strings.expenses,
      controller: _scroll,
      onRefresh: _reload,
      actions: [
        if (_expenses.isNotEmpty)
          TextButton(
            onPressed: _toggleSelecting,
            child: Text(_selecting ? strings.done : strings.select),
          ),
        IconButton(
          tooltip: strings.newExpense,
          onPressed: () => _open('/expenses/new'),
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
              Row(
                children: [
                  IconButton(
                    tooltip: strings.previousMonth,
                    onPressed: () => _shiftMonth(-1),
                    icon: Icon(AppIcons.back(context)),
                  ),
                  Expanded(
                    child: Text(
                      monthName,
                      textAlign: TextAlign.center,
                      style: AppText.section,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.nextMonth,
                    onPressed: () => _shiftMonth(1),
                    icon: Icon(AppIcons.forward(context)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MoneyText(_summary.gross, large: true),
                    Text(
                      strings.receiptCount(_summary.count),
                      style: AppText.label,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilterBar<ExpenseFilter>(
                selected: _filter,
                onSelected: (value) {
                  setState(() => _filter = value);
                  unawaited(_load(reset: true));
                },
                options: [
                  (value: ExpenseFilter.all, label: strings.filterAll),
                  (value: ExpenseFilter.tour, label: strings.filterTourCosts),
                  (
                    value: ExpenseFilter.other,
                    label: strings.filterOtherExpenses,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selecting && _expenses.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.selectionCount(_selected.length),
                              style: AppText.label,
                            ),
                          ),
                          TextButton(
                            onPressed: _toggleAll,
                            child: Text(
                              _expenses.every(
                                    (e) => _selected.containsKey(e.id),
                                  )
                                  ? strings.deselectAll
                                  : strings.selectAll,
                            ),
                          ),
                        ],
                      ),
                      SecondaryButton(
                        label: strings.delete,
                        icon: AppIcons.delete,
                        onPressed: _selected.isEmpty ? null : _deleteSelected,
                      ),
                    ],
                  ),
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
              ] else if (_expenses.isEmpty && !_loading)
                EmptyState(
                  message: strings.noExpenses,
                  actionLabel: strings.newExpense,
                  onAction: () => _open('/expenses/new'),
                )
              else
                ...AppListRow.divided([
                  for (final expense in _expenses) _row(strings, expense),
                ]),
              if (_loading) const SkeletonList(),
              const SizedBox(height: AppSpacing.lg),
              StickyAction(
                child: PrimaryButton(
                  label: _selecting
                      ? strings.exportSelectionPdf
                      : strings.exportMonthPdf,
                  icon: AppIcons.pdf,
                  onPressed: () {
                    final empty = _selecting
                        ? _selected.isEmpty
                        : _summary.count == 0;
                    if (empty) {
                      showErrorSnack(
                        context,
                        _selecting
                            ? strings.pdfNothingSelected
                            : strings.pdfNothingToShow,
                      );
                      return;
                    }
                    unawaited(_selecting ? _exportSelection() : _exportPdf());
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(AppLocalizations strings, Expense expense) {
    final day = DateFormatter.date(expense.date).substring(0, 6);
    final checked = _selected.containsKey(expense.id);
    return AppListRow(
      icon: AppIcons.expense,
      leading: _selecting
          ? Checkbox(
              value: checked,
              onChanged: (_) => _toggle(expense),
              visualDensity: VisualDensity.compact,
            )
          : null,
      title: expense.title,
      subtitle: [
        day,
        if (expense.tourNumber != null)
          expense.tourNumber!
        else
          expenseCategoryText(strings, expense.category),
      ].join(' · '),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          MoneyText(expense.gross),
          Text(
            expense.hasReceipt ? strings.withReceipt : strings.withoutReceipt,
            style: AppText.label.copyWith(
              color: expense.hasReceipt ? AppColors.success : null,
            ),
          ),
        ],
      ),
      showChevron: !_selecting,
      onTap: _selecting
          ? () => _toggle(expense)
          : () => _open('/expenses/${expense.id}'),
    );
  }
}
