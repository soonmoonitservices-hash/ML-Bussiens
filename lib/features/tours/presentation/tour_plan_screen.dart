import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/drafts/form_drafts.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/load_calculator.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/draft_restored_banner.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/date_time_picker.dart';
import 'package:warenbestand/shared/widgets/inputs/quantity_input.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';
import 'package:warenbestand/shared/widgets/sheets/product_pick_sheet.dart';

/// Tour planen in zwei Schritten (Details, Beladung). Mit [tourId] wird die
/// Beladung eines vorhandenen Entwurfs bearbeitet.
class TourPlanScreen extends ConsumerStatefulWidget {
  const TourPlanScreen({this.tourId, super.key});

  final String? tourId;

  @override
  ConsumerState<TourPlanScreen> createState() => _TourPlanScreenState();
}

class _TourPlanScreenState extends ConsumerState<TourPlanScreen> {
  final _name = TextEditingController();
  final _items = <LoadItem>[];
  String? _tourId;
  TourDriver? _driver;
  DateTime _plannedAt = DateTime.now();
  int _step = 0;
  AppError? _error;
  bool _loading = false;

  /// Merkt den angefangenen Stand auf dem Gerät (nur bei neuer Tour).
  late final DraftSaver _saver;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    _tourId = widget.tourId;
    _saver = DraftSaver(
      drafts: ref.read(formDraftsProvider),
      form: widget.tourId == null ? 'tour_new' : null,
      snapshot: _draftSnapshot,
    );
    _name.addListener(_saver.touch);
    if (_tourId != null) {
      unawaited(_loadDraft());
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
    super.dispose();
  }

  /// Der Stand zum Merken; `null`, wenn noch nichts eingegeben ist.
  Map<String, Object?>? _draftSnapshot() {
    if (_driver == null &&
        _items.isEmpty &&
        _name.text.trim().isEmpty &&
        _tourId == null) {
      return null;
    }
    return {
      'step': _step,
      'tourId': _tourId,
      'driver': _driver == null
          ? null
          : {
              'id': _driver!.id,
              'name': _driver!.name,
              'vehicle': _driver!.vehicle,
            },
      'plannedAt': _plannedAt.toIso8601String(),
      'name': _name.text,
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
      _tourId = data['tourId'] as String?;
      _name.text = data['name'] as String? ?? '';
      final driver = data['driver'] as Map<String, dynamic>?;
      _driver = driver == null ? null : TourDriver.fromJson(driver);
      final planned = DateTime.tryParse('${data['plannedAt']}');
      if (planned != null && planned.isAfter(DateTime.now())) {
        _plannedAt = planned;
      }
      for (final raw in data['items'] as List<dynamic>? ?? const []) {
        final saved = raw as Map<String, dynamic>;
        final product = TourProduct.fromJson(
          saved['product'] as Map<String, dynamic>,
        );
        _items.add(
          LoadItem(
            product: product,
            quantity: Quantity(saved['qty'] as int, product.unit),
          ),
        );
      }
      _step = (data['step'] == 1 && _driver != null) ? 1 : 0;
      _draftRestored = true;
    } on Object catch (error) {
      // Unlesbarer Stand: weglassen und mit leerem Formular beginnen.
      debugPrint('Entwurf der Tour nicht lesbar: $error');
      _resetForm();
    }
  }

  /// Leeres Formular (ohne `setState`), gemerkter Stand weg.
  void _resetForm() {
    _saver.clear();
    _draftRestored = false;
    _step = 0;
    _tourId = null;
    _driver = null;
    _plannedAt = DateTime.now();
    _name.clear();
    _items.clear();
    _error = null;
    _loading = false;
  }

  /// „Verwerfen“: leeres Formular.
  void _discardDraft() => setState(_resetForm);

  Future<void> _loadDraft() async {
    setState(() => _loading = true);
    final repository = ref.read(toursRepositoryProvider);
    final tour = await repository.getById(_tourId!);
    final load = await repository.draftLoad(_tourId!);
    if (!mounted) return;
    switch ((tour, load)) {
      case (Success(value: final tour), Success(value: final items)):
        setState(() {
          _driver = TourDriver(id: tour.driverId, name: tour.driverName);
          _plannedAt = tour.plannedAt;
          _name.text = tour.name ?? '';
          _items
            ..clear()
            ..addAll(items);
          _step = 1;
          _loading = false;
        });
      case (Failure(:final error), _) || (_, Failure(:final error)):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _pickDriver() async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(toursRepositoryProvider);
    final picked = await showPickSheet<TourDriver>(
      context,
      title: strings.chooseDriver,
      loader: (query) async {
        final result = await repository.drivers(search: query);
        return switch (result) {
          Success(:final value) => [
            for (final driver in value)
              PickOption(
                value: driver,
                title: driver.name,
                subtitle: driver.vehicle,
              ),
          ],
          Failure(:final error) => throw Exception(error.message),
        };
      },
    );
    if (picked != null) setState(() => _driver = picked);
  }

  Future<void> _pickDate() async {
    final picked = await pickDateTime(context, initial: _plannedAt);
    if (picked != null) setState(() => _plannedAt = picked);
  }

  Future<void> _addProduct() async {
    final strings = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final repository = ref.read(toursRepositoryProvider);
    final chosen = _items.map((item) => item.product.id).toSet();
    final picked = await showProductPickSheet<TourProduct>(
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
                  title: product.displayName(language),
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
        _items.add(LoadItem(product: pick.value, quantity: pick.quantity));
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

  List<LoadItem> get _validItems =>
      _items.where((item) => item.quantity.base > 0).toList();

  /// Speichert den Entwurf und gibt die Tour-ID zurück; bei Fehler `null`.
  Future<String?> _saveDraft() async {
    final repository = ref.read(toursRepositoryProvider);
    final items = _validItems;
    if (_tourId == null) {
      final result = await repository.createDraft(
        driverId: _driver!.id,
        plannedAt: _plannedAt,
        name: _name.text,
        items: items,
      );
      switch (result) {
        case Success(:final value):
          _tourId = value;
          return value;
        case Failure(:final error):
          setState(() => _error = error);
          return null;
      }
    }
    final result = await repository.updateDraft(
      tourId: _tourId!,
      driverId: _driver!.id,
      plannedAt: _plannedAt,
      name: _name.text,
      items: items,
    );
    switch (result) {
      case Success():
        return _tourId;
      case Failure(:final error):
        setState(() => _error = error);
        return null;
    }
  }

  Future<void> _submit({required bool start}) async {
    final strings = AppLocalizations.of(context);
    if (start) {
      final confirmed = await showConfirmDialog(
        context,
        title: strings.startTour,
        message: strings.confirmStartTour,
        confirmLabel: strings.startTour,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final id = await _saveDraft();
    if (!mounted) return;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    if (start) {
      final result = await ref.read(toursRepositoryProvider).start(id);
      if (!mounted) return;
      if (result case Failure(:final error)) {
        setState(() {
          _loading = false;
          _error = error;
        });
        return;
      }
    }
    _saver.finish();
    showSuccessSnack(context, start ? strings.tourStarted : strings.draftSaved);
    context.pushReplacement('/tours/$id');
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: strings.planTour,
      onBackPressed: _step == 1 && widget.tourId == null
          ? () => setState(() => _step = 0)
          : null,
      children: [
        if (_draftRestored) DraftRestoredBanner(onDiscard: _discardDraft),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(
            '${strings.stepOf(_step + 1, 2)} · '
            '${_step == 0 ? strings.stepDetails : strings.stepLoad}',
            style: AppText.label,
          ),
        ),
        if (_step == 0) ..._details(strings) else ..._load(strings),
      ],
    );
  }

  List<Widget> _details(AppLocalizations strings) => [
    SectionHeader(strings.driverLabel),
    AppListRow(
      icon: AppIcons.driver,
      title: _driver?.name ?? strings.chooseDriver,
      subtitle: _driver?.vehicle,
      showChevron: true,
      onTap: _pickDriver,
    ),
    const Divider(),
    SectionHeader(strings.plannedAtLabel),
    AppListRow(
      icon: AppIcons.calendar,
      title: DateFormatter.dateTime(_plannedAt),
      showChevron: true,
      onTap: _pickDate,
    ),
    const Divider(),
    const SizedBox(height: AppSpacing.md),
    TextField(
      controller: _name,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: strings.tourNameOptional),
    ),
    const SizedBox(height: AppSpacing.lg),
    StickyAction(
      child: PrimaryButton(
        label: strings.next,
        onPressed: _driver == null ? null : () => setState(() => _step = 1),
      ),
    ),
  ];

  List<Widget> _load(AppLocalizations strings) {
    final labels = strings.quantityLabels;
    final summary = const LoadCalculator().summarize([
      for (final item in _items)
        LoadLine(
          quantity: item.quantity,
          buyPrice: item.product.buyPrice,
          sellPrice: item.product.sellPrice,
        ),
    ]);
    final canSubmit = _validItems.isNotEmpty && !_loading;
    return [
      SectionHeader(strings.tourLoad),
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
      SectionHeader(strings.tourValues),
      KeyValueRow(
        label: strings.loadValueBuy,
        value: MoneyFormatter.format(summary.costValue),
      ),
      KeyValueRow(
        label: strings.loadValueSell,
        value: MoneyFormatter.format(summary.sellValue),
      ),
      KeyValueRow(
        label: strings.expectedProfit,
        value: MoneyFormatter.format(summary.expectedProfit),
        strong: true,
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
          label: strings.startTour,
          loading: _loading,
          onPressed: canSubmit ? () => _submit(start: true) : null,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SecondaryButton(
        label: strings.saveDraft,
        onPressed: canSubmit ? () => _submit(start: false) : null,
      ),
    ];
  }

  Widget _itemBlock(
    AppLocalizations strings,
    QuantityLabels labels,
    int index,
  ) {
    final item = _items[index];
    final product = item.product;
    final breakdown = QuantityFormatter.cartonBreakdown(
      item.quantity,
      product.unitsPerCarton,
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
                child: Text(
                  product.displayName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: AppText.bodyStrong,
                ),
              ),
              IconButton(
                tooltip: strings.remove,
                onPressed: () => setState(() => _items.removeAt(index)),
                icon: const Icon(AppIcons.delete),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          QuantityInput(
            key: ValueKey(product.id),
            value: item.quantity,
            unitsPerCarton: product.unitsPerCarton,
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
