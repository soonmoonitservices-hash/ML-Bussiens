import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/features/reports/data/report_documents.dart';
import 'package:warenbestand/features/reports/domain/report.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';
import 'package:warenbestand/features/reports/presentation/revenue_chart.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Auswertungen: Zeitraum wählen, Kennzahlen mit Vergleich, Diagramm,
/// Top-Produkte, Ausgaben nach Kategorie, Fahrerstatistik und PDF-Bericht.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportRange _range = ReportRange.month;
  late ReportPeriod _period = ReportPeriod.of(_range, DateTime.now());
  ReportData? _data;
  AppError? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(reportsRepositoryProvider)
        .load(_period, _period.previous(_range));
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _data = value;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  void _selectRange(ReportRange range) {
    setState(() {
      _range = range;
      _period = ReportPeriod.of(range, DateTime.now());
    });
    unawaited(_load());
  }

  void _shift(int steps) {
    setState(() => _period = _period.shifted(_range, steps));
    unawaited(_load());
  }

  Future<void> _pickCustom() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: DateTimeRange(start: _period.from, end: _period.to),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _range = ReportRange.custom;
      _period = ReportPeriod(from: picked.start, to: picked.end);
    });
    await _load();
  }

  String _periodLabel(String locale) => switch (_range) {
    ReportRange.day => DateFormatter.date(_period.from),
    ReportRange.week =>
      '${AppLocalizations.of(context).weekShort} ${_period.isoWeek} · '
          '${DateFormatter.date(_period.from).substring(0, 6)}–'
          '${DateFormatter.date(_period.to).substring(0, 6)}',
    ReportRange.month => DateFormat.yMMMM(locale).format(_period.from),
    ReportRange.year => '${_period.from.year}',
    ReportRange.custom =>
      '${DateFormatter.date(_period.from)} – ${DateFormatter.date(_period.to)}',
  };

  Future<void> _exportPdf() async {
    final strings = AppLocalizations.of(context);
    final data = _data;
    if (data == null) return;
    final documents = ref.read(reportDocumentsProvider);
    final period = _period;
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.reportPdf,
        fileName: ReportDocuments.fileName(period),
        load: () => documents.build(
          period: period,
          data: data,
          labels: (
            revenue: strings.revenue,
            cost: strings.costOfGoods,
            expenses: strings.expenses,
            profit: strings.profit,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final data = _data;
    return AppScreen(
      title: strings.reports,
      onRefresh: _load,
      children: [
        FilterBar<ReportRange>(
          selected: _range,
          onSelected: (value) =>
              value == ReportRange.custom ? _pickCustom() : _selectRange(value),
          options: [
            (value: ReportRange.day, label: strings.rangeDay),
            (value: ReportRange.week, label: strings.rangeWeek),
            (value: ReportRange.month, label: strings.rangeMonth),
            (value: ReportRange.year, label: strings.rangeYear),
            (value: ReportRange.custom, label: strings.rangeCustom),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            IconButton(
              tooltip: strings.previousMonth,
              onPressed: () => _shift(-1),
              icon: Icon(AppIcons.back(context)),
            ),
            Expanded(
              child: InkWell(
                onTap: _range == ReportRange.custom ? _pickCustom : null,
                child: Text(
                  _periodLabel(locale),
                  textAlign: TextAlign.center,
                  style: AppText.section,
                ),
              ),
            ),
            IconButton(
              tooltip: strings.nextMonth,
              onPressed: () => _shift(1),
              icon: Icon(AppIcons.forward(context)),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          TextButton(onPressed: _load, child: Text(strings.retry)),
        ],
        if (_loading && data == null) const SkeletonList(),
        if (data != null) ..._content(strings, data),
      ],
    );
  }

  List<Widget> _content(AppLocalizations strings, ReportData data) {
    final labels = strings.quantityLabels;
    final empty =
        data.kpis.revenue.isZero &&
        data.kpis.expenses.isZero &&
        data.kpis.tourCount == 0;
    String change(Money current, Money previous) {
      final value = changePercent(current: current, previous: previous);
      return value == null
          ? ''
          : strings.changeToPrevious('${value > 0 ? '+' : ''}$value');
    }

    Widget kpi(
      String label,
      Money value,
      Money previous, {
      bool strong = false,
    }) => Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: strong ? AppText.bodyStrong : AppText.body),
                Text(change(value, previous), style: AppText.label),
              ],
            ),
          ),
          Text(
            MoneyFormatter.format(value),
            style: strong ? AppText.amountLarge : AppText.amount,
            textDirection: TextDirection.ltr,
          ),
        ],
      ),
    );

    return [
      SectionHeader(strings.kpiSection),
      ...AppListRow.divided([
        kpi(strings.revenue, data.kpis.revenue, data.previous.revenue),
        kpi(strings.costOfGoods, data.kpis.cost, data.previous.cost),
        kpi(strings.expenses, data.kpis.expenses, data.previous.expenses),
        kpi(
          strings.profit,
          data.kpis.profit,
          data.previous.profit,
          strong: true,
        ),
      ]),
      if (empty)
        EmptyState(message: strings.noReportData)
      else ...[
        SectionHeader(strings.chartRevenueVsExpenses),
        RevenueChart(points: data.points, granularity: _period.granularity),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
          child: Row(
            children: [
              _legend(AppColors.ink, strings.revenue),
              const SizedBox(width: AppSpacing.md),
              _legend(AppColors.line, strings.expenses),
            ],
          ),
        ),
      ],
      if (data.products.isNotEmpty) ...[
        SectionHeader(strings.topProducts),
        ...AppListRow.divided([
          for (final product in data.products)
            AppListRow(
              title: product.name,
              subtitle: QuantityFormatter.format(product.sold, labels: labels),
              trailing: Text(
                MoneyFormatter.format(product.revenue),
                style: AppText.amount,
                textDirection: TextDirection.ltr,
              ),
            ),
        ]),
      ],
      if (data.categories.isNotEmpty) ...[
        SectionHeader(strings.expensesByCategory),
        ..._categories(strings, data.categories),
      ],
      const SizedBox(height: AppSpacing.md),
      AppListRow(
        icon: AppIcons.driver,
        title: strings.driverStats,
        showChevron: true,
        onTap: () => context.push('/reports/drivers', extra: _period),
      ),
      const Divider(),
      const SizedBox(height: AppSpacing.lg),
      StickyAction(
        child: PrimaryButton(
          label: strings.reportPdf,
          icon: AppIcons.pdf,
          onPressed: _exportPdf,
        ),
      ),
    ];
  }

  Widget _legend(Color color, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 12, height: 12, color: color),
      const SizedBox(width: AppSpacing.xs),
      Text(text, style: AppText.label),
    ],
  );

  List<Widget> _categories(
    AppLocalizations strings,
    List<ReportCategory> categories,
  ) {
    final max = categories.fold<int>(
      1,
      (m, c) => c.net.cents > m ? c.net.cents : m,
    );
    return [
      for (final category in categories)
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoryText(strings, category.category),
                      style: AppText.body,
                    ),
                  ),
                  Text(
                    MoneyFormatter.format(category.net),
                    style: AppText.amount,
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              FractionallySizedBox(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: (category.net.cents / max).clamp(0.02, 1.0),
                child: Container(height: 4, color: AppColors.ink),
              ),
            ],
          ),
        ),
    ];
  }

  String _categoryText(AppLocalizations strings, String stored) =>
      switch (stored) {
        ExpenseCategories.vehicle => strings.categoryVehicle,
        ExpenseCategories.rent => strings.categoryRent,
        ExpenseCategories.maintenance => strings.categoryMaintenance,
        ExpenseCategories.meals => strings.categoryMeals,
        ExpenseCategories.other => strings.categoryOther,
        _ => stored,
      };
}
