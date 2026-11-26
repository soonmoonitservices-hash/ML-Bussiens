import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/relative_date.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/invoices/data/invoice_documents.dart';
import 'package:warenbestand/features/invoices/data/invoices_repository.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';
import 'package:warenbestand/features/invoices/presentation/invoice_status_label.dart';
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

/// Rechnungsliste: Summe offen, Filter, Suche, Nachladen.
class InvoicesListScreen extends ConsumerStatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  ConsumerState<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends ConsumerState<InvoicesListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _invoices = <Invoice>[];
  final _selection = ListSelection<Invoice>();
  Timer? _debounce;
  bool _busy = false;
  OpenInvoicesSummary _summary = OpenInvoicesSummary.empty;
  InvoiceFilter _filter = InvoiceFilter.all;
  AppError? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _selection.addListener(_rebuild);
    unawaited(_reload());
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

  Future<void> _reload() async {
    unawaited(_loadSummary());
    await _load(reset: true);
  }

  Future<void> _loadSummary() async {
    final result = await ref.read(invoicesRepositoryProvider).summary();
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
        .read(invoicesRepositoryProvider)
        .list(page: nextPage, search: _search.text, filter: _filter);
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _invoices.clear();
          _invoices.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == InvoicesRepository.pageSize;
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
    final hasFinal = chosen.any((invoice) => !invoice.isDraft);
    final confirmed = await confirmDeleteMany(
      context,
      chosen.length,
      extraWarning: hasFinal ? strings.confirmDeleteManyInvoices : null,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final repository = ref.read(invoicesRepositoryProvider);
    var failed = 0;
    for (final invoice in chosen) {
      if (await repository.deleteDraft(invoice.id) is Failure) failed++;
    }
    if (!mounted) return;
    _selection.clear();
    setState(() => _busy = false);
    if (failed == 0) {
      showSuccessSnack(context, strings.deletedMany(chosen.length));
    } else {
      showErrorSnack(context, strings.deleteManyFailed(failed));
    }
    await _reload();
  }

  Future<void> _shareSelected() async {
    final strings = AppLocalizations.of(context);
    setState(() => _busy = true);
    final repository = ref.read(invoicesRepositoryProvider);
    final documents = ref.read(invoiceDocumentsProvider);
    final files = <PdfShareFile>[];
    for (final invoice in _selection.values) {
      final items = await repository.items(invoice.id);
      if (items is! Success<List<InvoiceItem>>) continue;
      final pdf = await documents.open(invoice, items.value);
      if (pdf case Success(:final value)) {
        files.add((name: InvoiceDocuments.fileName(invoice), bytes: value));
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
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final filtered =
        _search.text.trim().isNotEmpty || _filter != InvoiceFilter.all;
    return AppScreen.slivers(
      title: strings.invoices,
      controller: _scroll,
      onRefresh: _reload,
      actions: [
        if (_invoices.isNotEmpty)
          TextButton(
            onPressed: _selection.toggleMode,
            child: Text(_selection.active ? strings.done : strings.select),
          ),
        IconButton(
          tooltip: strings.newInvoice,
          onPressed: () => _open('/invoices/new'),
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
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.statusOpenInvoice, style: AppText.label),
                    MoneyText(_summary.openGross, large: true),
                    Text(
                      strings.openSummary(_summary.overdueCount),
                      style: AppText.label.copyWith(
                        color: _summary.overdueCount > 0
                            ? AppColors.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSearchField(
                controller: _search,
                hint: strings.invoicesSearch,
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilterBar<InvoiceFilter>(
                selected: _filter,
                onSelected: (value) {
                  setState(() => _filter = value);
                  unawaited(_load(reset: true));
                },
                options: [
                  (value: InvoiceFilter.all, label: strings.filterAll),
                  (value: InvoiceFilter.open, label: strings.filterOpenNotes),
                  (value: InvoiceFilter.paid, label: strings.filterPaid),
                  (value: InvoiceFilter.overdue, label: strings.filterOverdue),
                  (value: InvoiceFilter.draft, label: strings.filterDrafts),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selection.active && _invoices.isNotEmpty)
                SelectionToolbar(
                  count: _selection.count,
                  busy: _busy,
                  allSelected: _selection.allSelected(
                    _invoices.map((i) => i.id),
                  ),
                  onToggleAll: () => _selection.toggleAll({
                    for (final invoice in _invoices) invoice.id: invoice,
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
              ] else if (_invoices.isEmpty && !_loading)
                EmptyState(
                  message: filtered ? strings.noResults : strings.noInvoices,
                  actionLabel: filtered ? null : strings.newInvoice,
                  onAction: () => _open('/invoices/new'),
                )
              else
                ...AppListRow.divided([
                  for (final invoice in _invoices)
                    AppListRow(
                      icon: AppIcons.invoice,
                      leading: _selection.active
                          ? Checkbox(
                              value: _selection.isSelected(invoice.id),
                              onChanged: (_) =>
                                  _selection.toggle(invoice.id, invoice),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                      title: invoice.recipientName,
                      subtitle: [
                        invoice.number ?? strings.invoiceDraftTitle,
                        RelativeDate.format(
                          strings.dateLabels,
                          invoice.date,
                          now: DateTime.now(),
                        ),
                        if (invoice.dueDate != null &&
                            (invoice.status == InvoiceStatus.open ||
                                invoice.status == InvoiceStatus.overdue))
                          RelativeDate.due(
                            strings.dateLabels,
                            invoice.dueDate!,
                            now: DateTime.now(),
                          ).text,
                      ].join(' · '),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          MoneyText(invoice.gross),
                          const SizedBox(height: AppSpacing.xxs),
                          InvoiceStatusLabel(invoice.status),
                        ],
                      ),
                      showChevron: !_selection.active,
                      onTap: _selection.active
                          ? () => _selection.toggle(invoice.id, invoice)
                          : () => _open('/invoices/${invoice.id}'),
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
