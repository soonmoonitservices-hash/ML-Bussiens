import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/features/reports/domain/report.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';

/// Auswertungen: nur Lesen. Alle Zahlen berechnet die Datenbank
/// (`report_*`-Funktionen); die App zeigt sie an.
final class ReportsRepository {
  const ReportsRepository(this._client);

  final SupabaseClient _client;

  /// Lädt alle Daten des Zeitraums und des Vorzeitraums.
  Future<Result<ReportData>> load(ReportPeriod period, ReportPeriod previous) =>
      guard(() async {
        final results = await Future.wait([
          _kpis(period),
          _kpis(previous),
          _rows('report_timeseries', {
            ..._range(period),
            'p_granularity': period.granularity.dbValue,
          }),
          _rows('report_top_products', {..._range(period), 'p_limit': 5}),
          _rows('report_expenses_by_category', _range(period)),
          _rows('report_driver_stats', _range(period)),
        ]);
        return ReportData(
          kpis: results[0] as ReportKpis,
          previous: results[1] as ReportKpis,
          points: [
            for (final row in results[2] as List<Map<String, dynamic>>)
              ReportPoint.fromJson(row),
          ],
          products: [
            for (final row in results[3] as List<Map<String, dynamic>>)
              ReportProduct.fromJson(row),
          ],
          categories: [
            for (final row in results[4] as List<Map<String, dynamic>>)
              ReportCategory.fromJson(row),
          ],
          drivers: [
            for (final row in results[5] as List<Map<String, dynamic>>)
              DriverStat.fromJson(row),
          ],
        );
      });

  /// Nur die Kennzahlen des Zeitraums (Startseite).
  Future<Result<ReportKpis>> kpisFor(ReportPeriod period) =>
      guard(() => _kpis(period));

  /// Nur die Fahrerstatistik des Zeitraums.
  Future<Result<List<DriverStat>>> driverStats(ReportPeriod period) =>
      guard(() async {
        final rows = await _rows('report_driver_stats', _range(period));
        return [for (final row in rows) DriverStat.fromJson(row)];
      });

  Map<String, Object?> _range(ReportPeriod period) => {
    'p_from': DateFormatter.iso(period.from),
    'p_to': DateFormatter.iso(period.to),
  };

  Future<ReportKpis> _kpis(ReportPeriod period) async {
    final rows = await _rows('report_kpis', _range(period));
    return ReportKpis.fromJson(rows.first);
  }

  Future<List<Map<String, dynamic>>> _rows(
    String function,
    Map<String, Object?> params,
  ) async {
    final result = await _client.rpc<List<dynamic>>(function, params: params);
    return result.cast<Map<String, dynamic>>();
  }
}
