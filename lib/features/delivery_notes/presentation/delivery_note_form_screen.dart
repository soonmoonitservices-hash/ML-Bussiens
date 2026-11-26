import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/drafts/form_drafts.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/draft_restored_banner.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/quantity_input.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';
import 'package:warenbestand/shared/widgets/sheets/product_pick_sheet.dart';

/// Lieferschein erstellen oder (als Entwurf) bearbeiten. Der Empfänger wird
/// frei eingetippt, es gibt keine Kundenverwaltung.
class DeliveryNoteFormScreen extends ConsumerStatefulWidget {
  const DeliveryNoteFormScreen({this.noteId, super.key});

  final String? noteId;

  @override
  ConsumerState<DeliveryNoteFormScreen> createState() =>
      _DeliveryNoteFormScreenState();
}

class _DeliveryNoteFormScreenState
    extends ConsumerState<DeliveryNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  final _items = <DeliveryDraftItem>[];

  DateTime _date = DateTime.now();
  DeliveryTour? _tour;
  String? _tourId;
  AppError? _error;
  String? _info;
  bool _loading = false;

  bool get _editing => widget.noteId != null;

  /// Merkt den angefangenen Stand auf dem Gerät (nur bei neuem Lieferschein).
  late final DraftSaver _saver;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    _saver = DraftSaver(
      drafts: ref.read(formDraftsProvider),
      form: _editing ? null : 'delivery_note_new',
      snapshot: _draftSnapshot,
    );
    for (final controller in [_name, _address, _note]) {
      controller.addListener(_saver.touch);
    }
    if (_editing) {
      unawaited(_loadExisting());
    } else {
      // Sofort einsetzen, noch vor dem ersten Bild: kein Warten, kein Netz.
      _restoreDraft();
      _saver.start();
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _saver.touch();
  }

  @override
  void dispose() {
    _saver.dispose();
    _name.dispose();
    _address.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Der Stand zum Merken; `null`, wenn noch nichts eingegeben ist.
  Map<String, Object?>? _draftSnapshot() {
    if (_name.text.trim().isEmpty &&
        _address.text.trim().isEmpty &&
        _note.text.trim().isEmpty &&
        _items.isEmpty &&
        _tourId == null) {
      return null;
    }
    final tour = _tour;
    return {
      'name': _name.text,
      'address': _address.text,
      'note': _note.text,
      'date': _date.toIso8601String(),
      'tourId': _tourId,
      'tour': tour == null
          ? null
          : {
              'id': tour.id,
              'number': tour.number,
              'driver_name': tour.driverName,
              'planned_at': tour.plannedAt.toUtc().toIso8601String(),
            },
      'items': [
        // Mit allen Produktangaben: Das Einsetzen braucht keine Abfrage.
        for (final item in _items)
          {'product': item.product.toJson(), 'qty': item.quantity.base},
      ],
    };
  }

  /// Setzt den gemerkten Stand ein (ohne `setState`, nur beim Öffnen).
  void _restoreDraft() {
    final draft = _saver.read();
    if (draft == null) return;
    final data = draft.data;
    try {
      _name.text = data['name'] as String? ?? '';
      _address.text = data['address'] as String? ?? '';
      _note.text = data['note'] as String? ?? '';
      // Ein altes Datum nicht übernehmen: dann gilt wieder heute.
      final date = DateTime.tryParse('${data['date']}');
      if (date != null && draft.isFromToday) _date = date;
      _tourId = data['tourId'] as String?;
      final tour = data['tour'] as Map<String, dynamic>?;
      _tour = tour == null ? null : DeliveryTour.fromJson(tour);
      for (final raw in data['items'] as List<dynamic>? ?? const []) {
        final saved = raw as Map<String, dynamic>;
        final product = DeliveryProduct.fromJson(
          saved['product'] as Map<String, dynamic>,
        );
        _items.add(
          DeliveryDraftItem(
            product: product,
            quantity: Quantity(saved['qty'] as int, product.unit),
          ),
        );
      }
      _draftRestored = true;
    } on Object catch (error) {
      // Unlesbarer Stand: weglassen und mit leerem Formular beginnen.
      debugPrint('Entwurf des Lieferscheins nicht lesbar: $error');
      _resetForm();
    }
  }

  /// Leeres Formular (ohne `setState`), gemerkter Stand weg.
  void _resetForm() {
    _saver.clear();
    _draftRestored = false;
    _name.clear();
    _address.clear();
    _note.clear();
    _date = DateTime.now();
    _tour = null;
    _tourId = null;
    _items.clear();
    _info = null;
    _error = null;
    _loading = false;
  }

  /// „Verwerfen“: leeres Formular.
  void _discardDraft() => setState(_resetForm);

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final note = await repository.getById(widget.noteId!);
    final items = await repository.items(widget.noteId!);
    // Alle Produkte der Positionen laden (nicht nur die ersten 50 der Liste).
    final products = await repository.productsByIds([
      if (items case Success(:final value))
        for (final item in value) item.productId,
    ]);
    if (!mounted) return;
    switch ((note, items, products)) {
      case (
        Success(value: final note),
        Success(value: final items),
        Success(value: final products),
      ):
        final byId = {for (final p in products) p.id: p};
        setState(() {
          _name.text = note.recipientName;
          _address.text = note.recipientAddress;
          _note.text = note.note ?? '';
          _date = note.date;
          _tourId = note.tourId;
          _items
            ..clear()
            ..addAll([
              for (final item in items)
                if (byId[item.productId] case final product?)
                  DeliveryDraftItem(product: product, quantity: item.quantity),
            ]);
          _loading = false;
        });
      case (Failure(:final error), _, _) ||
          (_, Failure(:final error), _) ||
          (_, _, Failure(:final error)):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _pickTour() async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final picked = await showPickSheet<DeliveryTour>(
      context,
      title: strings.chooseTour,
      searchable: false,
      loader: (_) async {
        final result = await repository.tours();
        final tours = switch (result) {
          Success(:final value) => value,
          Failure(:final error) => throw Exception(error.message),
        };
        return [
          for (final tour in tours)
            PickOption<DeliveryTour>(
              value: tour,
              title: tour.number ?? tour.driverName,
              subtitle:
                  '${tour.driverName} · ${DateFormatter.date(tour.plannedAt)}',
            ),
        ];
      },
    );
    if (!mounted) return;
    if (picked == null) return;
    final result = await repository.tourItems(picked.id);
    if (!mounted) return;
    setState(() {
      _tour = picked;
      _tourId = picked.id;
      if (result case Success(:final value)) {
        _items
          ..clear()
          ..addAll(value);
        _info = strings.tourItemsTaken;
      }
    });
  }

  Future<void> _addProduct() async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final chosen = _items.map((item) => item.product.id).toSet();
    final picked = await showProductPickSheet<DeliveryProduct>(
      context,
      title: strings.addProduct,
      searchHint: strings.searchProducts,
      loader: (query) async {
        final result = await repository.products(search: query);
        return switch (result) {
          Success(:final value) => [
            for (final product in value)
              if (!chosen.contains(product.id))
                ProductPickOption(
                  id: product.id,
                  value: product,
                  title: product.name,
                  subtitle: product.sku,
                  unit: product.unit,
                  unitsPerCarton: product.unitsPerCarton,
                ),
          ],
          Failure(:final error) => throw Exception(error.message),
        };
      },
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final pick in picked) {
        _items.add(
          DeliveryDraftItem(product: pick.value, quantity: pick.quantity),
        );
      }
      // Position steht dort, wo das Produkt in der Produktliste steht.
      final sorted = sortByProductOrder(
        _items,
        (item) => item.product.sortOrder,
      );
      _items
        ..clear()
        ..addAll(sorted);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  /// Speichert den Lieferschein und gibt die ID zurück; bei Fehler `null`.
  Future<String?> _save() async {
    final strings = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return null;
    final items = _items.where((item) => item.quantity.base > 0).toList();
    if (items.isEmpty) {
      setState(() => _error = DatabaseError(strings.itemsRequired));
      return null;
    }
    final input = DeliveryNoteInput(
      recipientName: _name.text,
      recipientAddress: _address.text,
      date: _date,
      tourId: _tourId,
      note: _note.text,
      items: items,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(deliveryNotesRepositoryProvider);
    if (_editing) {
      final result = await repository.updateDraft(widget.noteId!, input);
      if (!mounted) return null;
      switch (result) {
        case Success():
          return widget.noteId;
        case Failure(:final error):
          setState(() {
            _loading = false;
            _error = error;
          });
          return null;
      }
    }
    final result = await repository.create(input);
    if (!mounted) return null;
    switch (result) {
      case Success(:final value):
        return value;
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
        return null;
    }
  }

  Future<void> _saveAndOpen() async {
    final id = await _save();
    if (id == null || !mounted) return;
    showSuccessSnack(context, AppLocalizations.of(context).draftSaved);
    if (_editing) {
      UnsavedChangesGuard.disarm(context);
      context.pop();
    } else {
      _saver.finish();
      context.pushReplacement('/delivery-notes/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = strings.quantityLabels;
    return AppScreen(
      title: _editing ? strings.edit : strings.newDeliveryNote,
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (_draftRestored) DraftRestoredBanner(onDiscard: _discardDraft),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: strings.recipientName),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: strings.recipientAddress,
                ),
              ),
              SectionHeader(strings.dateLabel),
              AppListRow(
                icon: AppIcons.calendar,
                title: DateFormatter.date(_date),
                showChevron: true,
                onTap: _pickDate,
              ),
              const Divider(),
              SectionHeader(strings.tourOptional),
              AppListRow(
                icon: AppIcons.tour,
                title:
                    _tour?.number ??
                    (_tourId == null ? strings.noTour : strings.tourDetails),
                subtitle: _tour?.driverName,
                showChevron: true,
                onTap: _pickTour,
              ),
              const Divider(),
              if (_tourId != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _tour = null;
                      _tourId = null;
                    }),
                    child: Text(strings.noTour),
                  ),
                ),
              if (_info != null) ...[
                const SizedBox(height: AppSpacing.sm),
                NoticeBanner(message: _info!, kind: NoticeKind.success),
              ],
              SectionHeader(strings.products),
              if (_items.isEmpty)
                EmptyState(message: strings.noItemsYet)
              else
                ...AppListRow.divided([
                  for (var i = 0; i < _items.length; i++)
                    _itemBlock(strings, labels, i),
                ]),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: strings.addProduct,
                icon: AppIcons.add,
                onPressed: _addProduct,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.noteLabel),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              StickyAction(
                child: PrimaryButton(
                  label: strings.saveDraft,
                  loading: _loading,
                  onPressed: _saveAndOpen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemBlock(
    AppLocalizations strings,
    QuantityLabels labels,
    int index,
  ) {
    final item = _items[index];
    final breakdown = QuantityFormatter.cartonBreakdown(
      item.quantity,
      item.product.unitsPerCarton,
      labels: labels,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.product.name, style: AppText.bodyStrong),
              ),
              IconButton(
                tooltip: strings.remove,
                onPressed: () => setState(() => _items.removeAt(index)),
                icon: const Icon(AppIcons.delete),
              ),
            ],
          ),
          QuantityInput(
            key: ValueKey(item.product.id),
            value: item.quantity,
            unitsPerCarton: item.product.unitsPerCarton,
            onChanged: (value) =>
                setState(() => _items[index] = item.withQuantity(value)),
          ),
          if (item.quantity.base > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                '= ${QuantityFormatter.format(item.quantity, labels: labels)}'
                '${breakdown == null ? '' : ' ($breakdown)'}',
                style: AppText.label,
              ),
            ),
        ],
      ),
    );
  }
}
