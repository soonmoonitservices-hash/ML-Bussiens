import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/reports/domain/report.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Balkendiagramm: Umsatz (dunkel) gegen Ausgaben (hellgrau) je Tag, Woche
/// oder Monat. Ohne Verlauf, ohne Schatten, ohne Tooltips; Werte stehen für
/// Screenreader in der Beschreibung und in der Tabelle darüber.
class RevenueChart extends StatelessWidget {
  const RevenueChart({
    required this.points,
    required this.granularity,
    super.key,
  });

  final List<ReportPoint> points;
  final ReportGranularity granularity;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final maxCents = points.fold<int>(
      1,
      (max, p) => [
        max,
        p.revenue.cents,
        p.expenses.cents,
      ].reduce((a, b) => a > b ? a : b),
    );
    final labelEvery = (points.length / 6).ceil().clamp(1, 1000);
    String label(DateTime date) => switch (granularity) {
      ReportGranularity.month => DateFormat.MMM(locale).format(date),
      _ => DateFormat.Md(locale).format(date),
    };
    final total = Money(points.fold<int>(0, (sum, p) => sum + p.revenue.cents));
    return Semantics(
      label:
          '${strings.chartRevenueVsExpenses}: ${MoneyFormatter.format(total)}',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxCents * 1.1,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: const BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= points.length ||
                        index % labelEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        label(points[index].start),
                        style: AppText.label,
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < points.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 2,
                  barRods: [
                    BarChartRodData(
                      toY: points[i].revenue.cents.toDouble(),
                      color: AppColors.ink,
                      width: points.length > 20 ? 4 : 8,
                      borderRadius: BorderRadius.zero,
                    ),
                    BarChartRodData(
                      toY: points[i].expenses.cents.toDouble(),
                      color: AppColors.line,
                      width: points.length > 20 ? 4 : 8,
                      borderRadius: BorderRadius.zero,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
