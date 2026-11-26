import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';
import 'package:warenbestand/features/tours/domain/settlement_calculator.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/features/tours/pdf/goods_list_pdf.dart';
import 'package:warenbestand/features/tours/presentation/add_expense_sheet.dart';
import 'package:warenbestand/features/tours/presentation/goods_list_screen.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/difference_banner.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/money_field.dart';
import 'package:warenbestand/shared/widgets/inputs/quantity_input.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Tour abschließen: Rückgabe je Produkt, Ausgaben, Bargeld, Live-Abrechnung.
/// Gerechnet wird hier nur zur Anzeige; die Datenbank prüft und friert ein.
class TourCloseScreen extends ConsumerStatefulWidget {
  const TourCloseScreen({required this.tourId, super.key});

  final String tourId;

  @override
  ConsumerState<TourCloseScreen> createState() => _TourCloseScreenState();
}

class _TourCloseScreenState extends ConsumerState<TourCloseScreen> {
  final _cash = TextEditingController();
  final _reason = TextEditingController();
  final _returned = <String, Quantity>{};
  final _gifts = <String, Quantity>{};
  final _removals = <String, Map<String, CartonRemoval>>{};
  Map<String, List<TourContent>> _contents = const {};
  Tour? _tour;
  List<TourItem> _items = const [];
  List<TourExpense> _expenses = const [];
  bool _cashIncludesVat = false;
  AppError? _error;
  String? _reasonError;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _cash.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(toursRepositoryProvider);
    final items = await repository.items(widget.tourId);
    final expenses = await repository.expenses(widget.tourId);
    final includesVat = await repository.cashIncludesVat();
    final cartonIds = [
      for (final item
          in (items is Success<List<TourItem>> ? items.value : <TourItem>[]))
        if (item.unit == ProductUnit.carton) item.productId,
    ];
    final contents = await repository.cartonContents(cartonIds);
    final tour = await repository.getById(widget.tourId);
    if (!mounted) return;
    switch ((items, expenses, includesVat)) {
      case (
        Success(value: final items),
        Success(value: final expenses),
        Success(value: final includesVat),
      ):
        setState(() {
          _items = items;
          _expenses = expenses;
          _cashIncludesVat = includesVat;
          if (contents case Success(:final value)) _contents = value;
          if (tour case Success(:final value)) _tour = value;
          for (final item in items) {
            _returned.putIfAbsent(
              item.productId,
              () => Quantity.zero(item.unit),
            );
          }
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

  /// Geschenk hinzufügen: ein Produkt der Tour wählen; die Menge folgt im Feld.
  Future<void> _addGift() async {
    final strings = AppLocalizations.of(context);
    final labels = strings.quantityLabels;
    final candidates = [
      for (final item in _items)
        if (!_gifts.containsKey(item.productId)) item,
    ];
    final picked = await showPickSheet<TourItem>(
      context,
      title: strings.addGift,
      searchable: false,
      loader: (_) async => [
        for (final item in candidates)
          PickOption(
            value: item,
            title: item.name,
            trailing: QuantityFormatter.format(item.loaded, labels: labels),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() => _gifts[picked.productId] = Quantity(1, picked.unit));
  }

  Future<void> _reloadExpenses() async {
    final result = await ref
        .read(toursRepositoryProvider)
        .expenses(widget.tourId);
    if (!mounted) return;
    if (result case Success(:final value)) setState(() => _expenses = value);
  }

  Future<void> _addExpense() async {
    final input = await showAddExpenseSheet(context);
    if (input == null || !mounted) return;
    final result = await ref
        .read(toursRepositoryProvider)
        .addExpense(widget.tourId, input);
    if (!mounted) return;
    if (result case Failure(:final error)) setState(() => _error = error);
    await _reloadExpenses();
  }

  Future<void> _deleteExpense(TourExpense expense) async {
    final result = await ref
        .read(toursRepositoryProvider)
        .deleteExpense(expense.id);
    if (!mounted) return;
    if (result case Failure(:final error)) setState(() => _error = error);
    await _reloadExpenses();
  }

  /// Die Tour-Positionen mit den aktuellen Eingaben für die Warenlisten.
  List<GoodsInput> _goodsInputs(AppLocalizations strings) {
    final language = Localizations.localeOf(context).languageCode;
    return [
      for (final item in _items)
        GoodsInput(
          name: item.name,
          loaded: item.loaded,
          returned: _returned[item.productId] ?? Quantity.zero(item.unit),
          gift: _gifts[item.productId] ?? Quantity.zero(item.unit),
          sellPrice: item.sellPrice,
          removals: [
            for (final content
                in _contents[item.productId] ?? const <TourContent>[])
              if (_removals[item.productId]?[content.productId] != null &&
                  !_removals[item.productId]![content.productId]!.isEmpty)
                GoodsRemovalInput(
                  label: strings.removalLabel(
                    content.displayName(language),
                    item.name,
                  ),
                  returned:
                      _removals[item.productId]![content.productId]!.returned,
                  gift: _removals[item.productId]![content.productId]!.gift,
                  sellPrice: content.sellPrice,
                ),
          ],
        ),
    ];
  }

  void _openGoods(AppLocalizations strings, GoodsListKind kind) {
    final inputs = _goodsInputs(strings);
    final tour = _tour;
    unawaited(
      context.push<void>(
        '/tour-goods',
        extra: GoodsListArgs(
          kind: kind,
          tourNumber: tour?.number ?? '',
          driverName: tour?.driverName ?? '',
          date: tour?.plannedAt ?? DateTime.now(),
          lines: kind == GoodsListKind.sold
              ? GoodsLists.sold(inputs)
              : GoodsLists.returned(inputs),
        ),
      ),
    );
  }

  /// Verkaufswert der aus dem Karton entfernten Produkte (mindert den Umsatz).
  Money _removedRevenue(TourItem item) {
    var total = Money.zero;
    for (final content in _contents[item.productId] ?? const <TourContent>[]) {
      final removal = _removals[item.productId]?[content.productId];
      if (removal == null) continue;
      final qty = Quantity(
        removal.returned.base + removal.gift.base,
        content.unit,
      );
      total += qty.valueAt(content.sellPrice);
    }
    return total;
  }

  /// Einkaufswert der zurückgebrachten Produkte (mindert den Wareneinsatz).
  Money _removedCost(TourItem item) {
    var total = Money.zero;
    for (final content in _contents[item.productId] ?? const <TourContent>[]) {
      final removal = _removals[item.productId]?[content.productId];
      if (removal == null) continue;
      total += removal.returned.valueAt(content.buyPrice);
    }
    return total;
  }

  /// Zu viele einzelne Produkte aus einem Karton entfernt?
  bool _tooManyRemoved(TourItem item) {
    final billed =
        item.loaded.base -
        (_returned[item.productId]?.base ?? 0) -
        (_gifts[item.productId]?.base ?? 0);
    for (final content in _contents[item.productId] ?? const <TourContent>[]) {
      final removal = _removals[item.productId]?[content.productId];
      if (removal == null) continue;
      if (removal.returned.base + removal.gift.base >
          content.perCarton * billed) {
        return true;
      }
    }
    return false;
  }

  Settlement? _settlement(Money cash) {
    try {
      return const SettlementCalculator().calculate(
        lines: [
          for (final item in _items)
            SettlementLine(
              loaded: item.loaded,
              returned: _returned[item.productId] ?? Quantity.zero(item.unit),
              gift: _gifts[item.productId],
              removedRevenue: _removedRevenue(item),
              removedCost: _removedCost(item),
              buyPrice: item.buyPrice,
              sellPrice: item.sellPrice,
              vatRate: item.vatRate,
            ),
        ],
        expenses: [
          for (final e in _expenses)
            SettlementExpense(gross: e.gross, vatRate: e.vatRate),
        ],
        cashReceived: cash,
        cashIncludesVat: _cashIncludesVat,
      );
    } on ReturnExceedsLoadException {
      return null;
    }
  }

  Future<void> _close(Money cash, Settlement settlement) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.closeTour,
      message: strings.confirmCloseTour,
      confirmLabel: strings.confirmClose,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _reasonError = null;
    });
    final result = await ref
        .read(toursRepositoryProvider)
        .close(
          tourId: widget.tourId,
          returns: {
            for (final entry in _returned.entries) entry.key: entry.value.base,
          },
          cashReceivedCents: cash.cents,
          gifts: {
            for (final entry in _gifts.entries) entry.key: entry.value.base,
          },
          removals: _removals,
          differenceReason: _reason.text,
        );
    if (!mounted) return;
    switch (result) {
      case Success():
        showSuccessSnack(context, strings.tourClosed);
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading || (_items.isEmpty && _error != null)) {
      return AppScreen(
        title: strings.closeTour,
        children: [
          if (_loading)
            const SkeletonList()
          else ...[
            NoticeBanner(
              message: _error!.localized(strings),
              kind: NoticeKind.error,
            ),
            TextButton(onPressed: _load, child: Text(strings.retry)),
          ],
        ],
      );
    }
    final labels = strings.quantityLabels;
    final cash = MoneyField.read(_cash);
    final settlement = _settlement(cash ?? Money.zero);
    final tooHigh = [
      for (final item in _items)
        if ((_returned[item.productId] ?? Quantity.zero(item.unit)) +
                (_gifts[item.productId] ?? Quantity.zero(item.unit)) >
            item.loaded)
          item,
    ];
    final tooMany = _items.where(_tooManyRemoved).toList();
    final canClose =
        !_busy &&
        cash != null &&
        settlement != null &&
        tooHigh.isEmpty &&
        tooMany.isEmpty;
    return AppScreen(
      title: strings.closeTour,
      children: [
        NoticeBanner(message: strings.closeInfo, kind: NoticeKind.warning),
        SectionHeader(strings.tourLoad),
        ...AppListRow.divided([
          for (final item in _items) _itemBlock(strings, labels, item),
        ]),
        SectionHeader(strings.gifts),
        if (_gifts.isNotEmpty)
          ...AppListRow.divided([
            for (final entry in _gifts.entries)
              _giftBlock(
                strings,
                labels,
                _items.firstWhere((item) => item.productId == entry.key),
              ),
          ]),
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(
          label: strings.addGift,
          icon: AppIcons.add,
          onPressed: _items.length > _gifts.length ? _addGift : null,
        ),
        SectionHeader(strings.expenses),
        if (_expenses.isNotEmpty)
          ...AppListRow.divided([
            for (final expense in _expenses)
              AppListRow(
                title: expense.title,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      MoneyFormatter.format(expense.gross),
                      style: AppText.amount,
                      textDirection: TextDirection.ltr,
                    ),
                    IconButton(
                      tooltip: strings.remove,
                      onPressed: () => _deleteExpense(expense),
                      icon: const Icon(AppIcons.delete),
                    ),
                  ],
                ),
              ),
          ]),
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(
          label: strings.addExpense,
          icon: AppIcons.add,
          onPressed: _addExpense,
        ),
        SectionHeader(strings.cashFromDriver),
        MoneyField(
          controller: _cash,
          label: strings.cashFromDriver,
          onChanged: (_) => setState(() => _reasonError = null),
        ),
        if (settlement != null) ...[
          SectionHeader(strings.tourValues),
          KeyValueRow(
            label: strings.revenue,
            value: MoneyFormatter.format(
              _cashIncludesVat
                  ? settlement.revenueGross
                  : settlement.revenueNet,
            ),
          ),
          KeyValueRow(
            label: strings.expenses,
            value: MoneyFormatter.format(-settlement.expensesGross),
          ),
          KeyValueRow(
            label: strings.expectedCash,
            value: MoneyFormatter.format(settlement.expectedCash),
            strong: true,
          ),
          if (cash != null) ...[
            if (!settlement.isBalanced) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _reason,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() => _reasonError = null),
                decoration: InputDecoration(
                  labelText: strings.reasonLabel,
                  errorText: _reasonError,
                ),
              ),
            ],
          ],
          const SizedBox(height: AppSpacing.sm),
          KeyValueRow(
            label: strings.costOfGoods,
            value: MoneyFormatter.format(settlement.cost),
          ),
          KeyValueRow(
            label: strings.profit,
            value: MoneyFormatter.format(settlement.profit),
            strong: true,
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            label: strings.soldGoods,
            onPressed: () => _openGoods(strings, GoodsListKind.sold),
          ),
          const SizedBox(height: AppSpacing.xs),
          SecondaryButton(
            label: strings.returnedGoods,
            onPressed: () => _openGoods(strings, GoodsListKind.returned),
          ),
        ],
        for (final item in tooHigh) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: strings.returnTooHigh(item.name),
            kind: NoticeKind.error,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        if (cash == null && !_busy)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(strings.cashRequired, style: AppText.label),
          ),
        const SizedBox(height: AppSpacing.lg),
        StickyAction(
          summary: settlement == null || cash == null
              ? null
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DifferenceBanner(difference: settlement.difference),
                    if (settlement.difference.cents.abs() > 5000) ...[
                      const SizedBox(height: AppSpacing.xs),
                      NoticeBanner(
                        message: strings.checkAmount,
                        kind: NoticeKind.warning,
                      ),
                    ],
                  ],
                ),
          child: PrimaryButton(
            label: strings.confirmClose,
            loading: _busy,
            onPressed: canClose ? () => _close(cash, settlement) : null,
          ),
        ),
      ],
    );
  }

  List<Widget> _removalFields(AppLocalizations strings, TourItem item) {
    final language = Localizations.localeOf(context).languageCode;
    return [
      const SizedBox(height: AppSpacing.sm),
      Text(strings.cartonRemovalsTitle, style: AppText.bodyStrong),
      Text(strings.cartonRemovalsHint, style: AppText.label),
      for (final content in _contents[item.productId]!) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(content.displayName(language), style: AppText.body),
        const SizedBox(height: AppSpacing.xxs),
        Text(strings.returnedQty, style: AppText.label),
        QuantityInput(
          key: ValueKey('rm-r-${item.productId}-${content.productId}'),
          value:
              _removals[item.productId]?[content.productId]?.returned ??
              Quantity.zero(content.unit),
          unitsPerCarton: content.unitsPerCarton,
          onChanged: (value) => setState(() {
            final current = _removals[item.productId]?[content.productId];
            (_removals[item.productId] ??=
                {})[content.productId] = CartonRemoval(
              returned: value,
              gift: current?.gift ?? Quantity.zero(content.unit),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(strings.removedGift, style: AppText.label),
        QuantityInput(
          key: ValueKey('rm-g-${item.productId}-${content.productId}'),
          value:
              _removals[item.productId]?[content.productId]?.gift ??
              Quantity.zero(content.unit),
          unitsPerCarton: content.unitsPerCarton,
          onChanged: (value) => setState(() {
            final current = _removals[item.productId]?[content.productId];
            (_removals[item.productId] ??=
                {})[content.productId] = CartonRemoval(
              returned: current?.returned ?? Quantity.zero(content.unit),
              gift: value,
            );
          }),
        ),
      ],
      if (_tooManyRemoved(item))
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: NoticeBanner(
            message: strings.removalTooMany,
            kind: NoticeKind.error,
          ),
        ),
    ];
  }

  Widget _giftBlock(
    AppLocalizations strings,
    QuantityLabels labels,
    TourItem item,
  ) {
    final gift = _gifts[item.productId] ?? Quantity.zero(item.unit);
    final available =
        item.loaded - (_returned[item.productId] ?? Quantity.zero(item.unit));
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
              Expanded(child: Text(item.name, style: AppText.bodyStrong)),
              IconButton(
                tooltip: strings.remove,
                onPressed: () => setState(() => _gifts.remove(item.productId)),
                icon: const Icon(AppIcons.delete),
              ),
            ],
          ),
          Text(
            strings.giftMax(
              QuantityFormatter.format(
                available.base < 0 ? Quantity.zero(item.unit) : available,
                labels: labels,
              ),
            ),
            style: AppText.label,
          ),
          const SizedBox(height: AppSpacing.xs),
          QuantityInput(
            key: ValueKey('gift-${item.productId}'),
            value: gift,
            unitsPerCarton: item.unitsPerCarton,
            onChanged: (value) =>
                setState(() => _gifts[item.productId] = value),
          ),
        ],
      ),
    );
  }

  Widget _itemBlock(
    AppLocalizations strings,
    QuantityLabels labels,
    TourItem item,
  ) {
    final returned = _returned[item.productId] ?? Quantity.zero(item.unit);
    final sold = item.loaded - returned;
    final soldValue = sold.base < 0 ? Money.zero : sold.valueAt(item.sellPrice);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.name, style: AppText.bodyStrong),
          Text(
            strings.loadedValue(
              QuantityFormatter.format(item.loaded, labels: labels),
            ),
            style: AppText.label,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(strings.returnedQty, style: AppText.label),
          QuantityInput(
            key: ValueKey(item.productId),
            value: returned,
            unitsPerCarton: item.unitsPerCarton,
            onChanged: (value) =>
                setState(() => _returned[item.productId] = value),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            strings.soldValue(
              QuantityFormatter.format(
                sold.base < 0 ? Quantity.zero(item.unit) : sold,
                labels: labels,
              ),
              MoneyFormatter.format(soldValue),
            ),
            style: AppText.label,
          ),
          if ((_contents[item.productId] ?? const <TourContent>[]).isNotEmpty)
            ..._removalFields(strings, item),
        ],
      ),
    );
  }
}
