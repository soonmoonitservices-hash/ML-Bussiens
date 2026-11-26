import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/reports/domain/report.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Fahrerstatistik des gewählten Zeitraums: je Fahrer eine Gruppe mit Touren,
/// Umsatz, Durchschnitt, Rücklaufquote und Kassendifferenzen.
class DriverStatsScreen extends ConsumerStatefulWidget {
  const DriverStatsScreen({this.period, super.key});

  /// Zeitraum der Auswertung; ohne Angabe der aktuelle Monat.
  final ReportPeriod? period;

  @override
  ConsumerState<DriverStatsScreen> createState() => _DriverStatsScreenState();
}

class _DriverStatsScreenState extends ConsumerState<DriverStatsScreen> {
  late final ReportPeriod _period =
      widget.period ?? ReportPeriod.of(ReportRange.month, DateTime.now());
  List<DriverStat> _drivers = const [];
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
        .driverStats(_period);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _drivers = value;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: strings.driverStats,
      onRefresh: _load,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(
            '${DateFormatter.date(_period.from)} – '
            '${DateFormatter.date(_period.to)}',
            style: AppText.label,
          ),
        ),
        if (_loading)
          const SkeletonList()
        else if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          TextButton(onPressed: _load, child: Text(strings.retry)),
        ] else if (_drivers.isEmpty)
          EmptyState(message: strings.noReportData)
        else
          for (final driver in _drivers) ..._driver(strings, driver),
      ],
    );
  }

  List<Widget> _driver(AppLocalizations strings, DriverStat driver) => [
    Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSpacing.lg,
        start: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(driver.name, style: AppText.section),
    ),
    KeyValueRow(label: strings.tours, value: '${driver.tours}'),
    KeyValueRow(
      label: strings.revenue,
      value: MoneyFormatter.format(driver.revenue),
    ),
    KeyValueRow(
      label: strings.averagePerTour,
      value: MoneyFormatter.format(driver.averagePerTour),
    ),
    KeyValueRow(
      label: strings.returnRate,
      value: '${driver.returnRatePercent} %',
    ),
    KeyValueRow(
      label: strings.differences,
      value: MoneyFormatter.formatSigned(driver.differenceSum),
      valueColor: driver.shortageSum.isZero ? null : AppColors.error,
    ),
    const Divider(),
  ];
}
