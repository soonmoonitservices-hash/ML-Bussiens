import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/relative_date.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_note_documents.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_notes_repository.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';
import 'package:warenbestand/l10n/date_labels.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/selection/list_selection.dart';

/// Lieferscheinliste mit Suche und Filter Alle, Unterschrieben, Offen.
class DeliveryNotesListScreen extends ConsumerStatefulWidget {
  const DeliveryNotesListScreen({super.key});

  @override
  ConsumerState<DeliveryNotesListScreen> createState() =>
      _DeliveryNotesListScreenState();
}

class _DeliveryNotesListScreenState
    extends ConsumerState<DeliveryNotesListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _notes = <DeliveryNote>[];
  final _selection = ListSelection<DeliveryNote>();
  Timer? _debounce;
  bool _busy = false;
  DeliveryFilter _filter = DeliveryFilter.all;
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
        .read(deliveryNotesRepositoryProvider)
        .list(page: nextPage, search: _search.text, filter: _filter);
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _notes.clear();
          _notes.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == DeliveryNotesRepository.pageSize;
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
    final repository = ref.read(deliveryNotesRepositoryProvider);
    var failed = 0;
    for (final note in chosen) {
      if (await repository.delete(note.id) is Failure) failed++;
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
    setState(() => _busy = true);
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final documents = ref.read(deliveryNoteDocumentsProvider);
    final files = <PdfShareFile>[];
    for (final note in _selection.values) {
      final items = await repository.items(note.id);
      if (items is! Success<List<DeliveryNoteItem>>) continue;
      final pdf = await documents.open(note, items.value);
      if (pdf case Success(:final value)) {
        files.add((name: DeliveryNoteDocuments.fileName(note), bytes: value));
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
      title: strings.deliveryNotes,
      controller: _scroll,
      onRefresh: () => _load(reset: true),
      actions: [
        if (_notes.isNotEmpty)
          TextButton(
            onPressed: _selection.toggleMode,
            child: Text(_selection.active ? strings.done : strings.select),
          ),
        IconButton(
          tooltip: strings.newDeliveryNote,
          onPressed: () => _open('/delivery-notes/new'),
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
                hint: strings.deliveryNotesSearch,
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilterBar<DeliveryFilter>(
                selected: _filter,
                onSelected: (value) {
                  setState(() => _filter = value);
                  unawaited(_load(reset: true));
                },
                options: [
                  (value: DeliveryFilter.all, label: strings.filterAll),
                  (value: DeliveryFilter.signed, label: strings.filterSigned),
                  (value: DeliveryFilter.open, label: strings.filterOpenNotes),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_selection.active && _notes.isNotEmpty)
                SelectionToolbar(
                  count: _selection.count,
                  busy: _busy,
                  allSelected: _selection.allSelected(_notes.map((n) => n.id)),
                  onToggleAll: () => _selection.toggleAll({
                    for (final note in _notes) note.id: note,
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
              ] else if (_notes.isEmpty && !_loading)
                EmptyState(
                  message: searching || _filter != DeliveryFilter.all
                      ? strings.noResults
                      : strings.noDeliveryNotes,
                  actionLabel: searching || _filter != DeliveryFilter.all
                      ? null
                      : strings.newDeliveryNote,
                  onAction: () => _open('/delivery-notes/new'),
                )
              else
                ...AppListRow.divided([
                  for (final note in _notes)
                    AppListRow(
                      icon: AppIcons.deliveryNote,
                      leading: _selection.active
                          ? Checkbox(
                              value: _selection.isSelected(note.id),
                              onChanged: (_) =>
                                  _selection.toggle(note.id, note),
                              visualDensity: VisualDensity.compact,
                            )
                          : null,
                      title: note.recipientName,
                      subtitle:
                          '${note.number} · '
                          '${RelativeDate.format(strings.dateLabels, note.date, now: DateTime.now())}',
                      // Kein „Entwurf“: ein Lieferschein ist mit dem Speichern fertig.
                      // Nur alte, in der App unterschriebene zeigen ihr Etikett.
                      trailing: note.isSigned
                          ? StatusLabel(
                              strings.statusSigned,
                              color: AppColors.success,
                              surface: AppColors.successSurface,
                            )
                          : null,
                      showChevron: !_selection.active,
                      onTap: _selection.active
                          ? () => _selection.toggle(note.id, note)
                          : () => _open('/delivery-notes/${note.id}'),
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
