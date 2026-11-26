import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/tours/data/tour_goods_documents.dart';
import 'package:warenbestand/features/tours/data/tours_repository.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/features/tours/pdf/goods_list_pdf.dart';
import 'package:warenbestand/features/tours/presentation/goods_list_screen.dart';
import 'package:warenbestand/features/tours/presentation/tour_status_label.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/code_text.dart';
import 'package:warenbestand/shared/widgets/display/difference_banner.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Tourdetail: Ladung, Werte und die Aktionen passend zum Status.
class TourDetailScreen extends ConsumerStatefulWidget {
  const TourDetailScreen({required this.tourId, super.key});

  final String tourId;

  @override
  ConsumerState<TourDetailScreen> createState() => _TourDetailScreenState();
}

class _TourDetailScreenState extends ConsumerState<TourDetailScreen> {
  Tour? _tour;
  List<TourItem> _items = const [];
  AppError? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  /// Tourabrechnung einer abgeschlossenen Tour als PDF (Vorschau mit Teilen).
  Future<void> _openSummary(Tour tour) async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(tourGoodsDocumentsProvider);
    final repository = ref.read(toursRepositoryProvider);
    final items = _items;
    await context.push<void>(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.tourSummaryPdf,
        fileName: TourGoodsDocuments.summaryFileName(tour.number ?? ''),
        load: () async {
          final expenses = await repository.expenses(tour.id);
          return switch (expenses) {
            Success(:final value) => await documents.summary(
              tour: tour,
              items: items,
              expenses: value,
            ),
            Failure(:final error) => Failure(error),
          };
        },
      ),
    );
  }

  /// „Verkaufte Ware“ bzw. „Zurückgeholte Ware“ einer abgeschlossenen Tour.
  Future<void> _openGoods(Tour tour, GoodsListKind kind) async {
    final strings = AppLocalizations.of(context);
    final removals = await ref.read(toursRepositoryProvider).removals(tour.id);
    if (!mounted) return;
    final rows = switch (removals) {
      Success(:final value) => value,
      Failure() => const <TourRemovalRow>[],
    };
    final inputs = [
      for (final item in _items)
        GoodsInput(
          name: item.name,
          loaded: item.loaded,
          returned: item.returned,
          gift: item.giftQty,
          sellPrice: item.sellPrice,
          removals: [
            for (final row in rows)
              if (row.cartonProductId == item.productId)
                GoodsRemovalInput(
                  label: strings.removalLabel(row.contentName, item.name),
                  returned: row.returned,
                  gift: row.gift,
                  sellPrice: row.sellPrice,
                ),
          ],
        ),
    ];
    if (!mounted) return;
    await context.push<void>(
      '/tour-goods',
      extra: GoodsListArgs(
        kind: kind,
        tourNumber: tour.number ?? '',
        driverName: tour.driverName,
        date: tour.plannedAt,
        lines: kind == GoodsListKind.sold
            ? GoodsLists.sold(inputs)
            : GoodsLists.returned(inputs),
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(toursRepositoryProvider);
    final tour = await repository.getById(widget.tourId);
    final items = await repository.items(widget.tourId);
    if (!mounted) return;
    switch ((tour, items)) {
      case (Success(value: final tour), Success(value: final items)):
        setState(() {
          _tour = tour;
          _items = items;
          _loading = false;
        });
      case (Failure(:final error), _) || (_, Failure(:final error)):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  /// Führt eine Funktion der Datenbank aus und lädt danach neu.
  Future<void> _run(
    Future<Result<void>> Function() action, {
    String? success,
    bool leave = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    switch (result) {
      case Success():
        if (success != null) showSuccessSnack(context, success);
        if (leave) {
          context.pop();
          return;
        }
        setState(() => _busy = false);
        await _load();
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  Future<void> _confirmAndRun(
    String message,
    String confirmLabel,
    Future<Result<void>> Function() action, {
    String? success,
    bool leave = false,
  }) async {
    final confirmed = await showConfirmDialog(
      context,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (confirmed && mounted) {
      await _run(action, success: success, leave: leave);
    }
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final tour = _tour;
    if (tour == null) {
      return AppScreen(
        title: strings.tourDetails,
        children: [
          if (_loading)
            const SkeletonList()
          else if (_error != null) ...[
            NoticeBanner(
              message: _error!.localized(strings),
              kind: NoticeKind.error,
            ),
            TextButton(onPressed: _load, child: Text(strings.retry)),
          ],
        ],
      );
    }
    final repository = ref.read(toursRepositoryProvider);
    final isChef = ref.read(sessionControllerProvider).canManage;
    final labels = strings.quantityLabels;
    final closed = tour.status == TourStatus.closed;
    return AppScreen(
      title: tour.title,
      onRefresh: _load,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (tour.number != null) ...[
                CodeText(tour.number!),
                const SizedBox(width: AppSpacing.sm),
              ],
              TourStatusLabel(tour.status),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        KeyValueRow(label: strings.driverLabel, value: tour.driverName),
        KeyValueRow(
          label: strings.plannedAtLabel,
          value: DateFormatter.dateTime(tour.plannedAt),
        ),
        if (tour.startedAt != null)
          KeyValueRow(
            label: strings.startedAtLabel,
            value: DateFormatter.dateTime(tour.startedAt!),
          ),
        if (tour.closedAt != null)
          KeyValueRow(
            label: strings.closedAtLabel,
            value: DateFormatter.dateTime(tour.closedAt!),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        SectionHeader(strings.tourLoad),
        ...AppListRow.divided([
          for (final item in _items)
            AppListRow(
              title: item.name,
              subtitle: closed
                  ? '${strings.returnedLabel}: '
                        '${QuantityFormatter.format(item.returned, labels: labels)}'
                        ' · ${strings.soldLabel}: '
                        '${QuantityFormatter.format(item.sold, labels: labels)}'
                  : null,
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    QuantityFormatter.format(item.loaded, labels: labels),
                    style: AppText.amount,
                    textDirection: TextDirection.ltr,
                  ),
                  Text(
                    MoneyFormatter.format(item.loaded.valueAt(item.sellPrice)),
                    style: AppText.label,
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
        ]),
        SectionHeader(strings.tourValues),
        if (closed)
          ..._closedValues(strings, tour)
        else
          ..._openValues(strings, tour),
        const SizedBox(height: AppSpacing.lg),
        ..._actions(strings, tour, repository, isChef: isChef),
      ],
    );
  }

  List<Widget> _openValues(AppLocalizations strings, Tour tour) => [
    KeyValueRow(
      label: strings.expectedRevenue,
      value: MoneyFormatter.format(tour.loadedValueSell),
    ),
    KeyValueRow(
      label: strings.loadValueBuy,
      value: MoneyFormatter.format(tour.loadedValueBuy),
    ),
    if (tour.liveExpensesGross.cents > 0)
      KeyValueRow(
        label: strings.expenses,
        value: MoneyFormatter.format(tour.liveExpensesGross),
      ),
    KeyValueRow(
      label: strings.expectedProfit,
      value: MoneyFormatter.format(tour.expectedProfit),
      strong: true,
    ),
  ];

  List<Widget> _closedValues(AppLocalizations strings, Tour tour) {
    String money(Money? value) =>
        value == null ? strings.notAvailable : MoneyFormatter.format(value);
    return [
      KeyValueRow(label: strings.revenue, value: money(tour.revenueNet)),
      KeyValueRow(label: strings.expenses, value: money(tour.expensesGross)),
      KeyValueRow(label: strings.expectedCash, value: money(tour.expectedCash)),
      KeyValueRow(label: strings.cashReceived, value: money(tour.cashReceived)),
      if (tour.difference != null) ...[
        const SizedBox(height: AppSpacing.xs),
        DifferenceBanner(difference: tour.difference!),
      ],
      if (tour.differenceReason != null && tour.differenceReason!.isNotEmpty)
        KeyValueRow(label: strings.reasonLabel, value: tour.differenceReason!),
      KeyValueRow(label: strings.costOfGoods, value: money(tour.cost)),
      KeyValueRow(
        label: strings.profit,
        value: money(tour.profit),
        strong: true,
      ),
    ];
  }

  List<Widget> _actions(
    AppLocalizations strings,
    Tour tour,
    ToursRepository repository, {
    required bool isChef,
  }) {
    switch (tour.status) {
      case TourStatus.draft:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.startTour,
              loading: _busy,
              onPressed: _items.isEmpty
                  ? null
                  : () => _confirmAndRun(
                      strings.confirmStartTour,
                      strings.startTour,
                      () => repository.start(tour.id),
                      success: strings.tourStarted,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.edit,
            onPressed: () => _open('/tours/${tour.id}/load'),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirmAndRun(
                    strings.confirmDeleteDraft,
                    strings.delete,
                    () => repository.deleteDraft(tour.id),
                    leave: true,
                  ),
          ),
        ];
      case TourStatus.active:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.closeTour,
              onPressed: () => _open('/tours/${tour.id}/close'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.undoStart,
            onPressed: _busy
                ? null
                : () => _confirmAndRun(
                    strings.confirmUndoStart,
                    strings.undoStart,
                    () => repository.undoStart(tour.id),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirmAndRun(
                    strings.confirmDeleteTour,
                    strings.delete,
                    () => repository.deleteDraft(tour.id),
                    leave: true,
                  ),
          ),
        ];
      case TourStatus.closed:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.tourSummaryPdf,
              icon: AppIcons.pdf,
              onPressed: () => _openSummary(tour),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.soldGoods,
            onPressed: () => _openGoods(tour, GoodsListKind.sold),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.returnedGoods,
            onPressed: () => _openGoods(tour, GoodsListKind.returned),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (isChef)
            SecondaryButton(
              label: strings.reopenTour,
              onPressed: _busy
                  ? null
                  : () => _confirmAndRun(
                      strings.reopenTour,
                      strings.reopenTour,
                      () => repository.reopen(tour.id),
                    ),
            ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirmAndRun(
                    strings.confirmDeleteTour,
                    strings.delete,
                    () => repository.deleteDraft(tour.id),
                    leave: true,
                  ),
          ),
        ];
    }
  }
}
