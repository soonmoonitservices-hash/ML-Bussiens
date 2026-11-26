import 'dart:typed_data';

import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/reports/domain/report.dart';
import 'package:warenbestand/features/reports/domain/report_period.dart';
import 'package:warenbestand/features/reports/pdf/report_pdf.dart';

/// Erzeugt den Auswertungsbericht als PDF. Nichts wird gespeichert.
final class ReportDocuments {
  ReportDocuments({required this._company, required this._loadFonts});

  final CompanyPdfSource _company;
  final Future<PdfFontBytes> Function() _loadFonts;
  PdfFontBytes? _fonts;

  static String fileName(ReportPeriod period) =>
      PdfFileName.report(from: period.from, to: period.to);

  /// Bericht mit den Texten der [labels] (Kennzahlen in der Sprache der App).
  Future<Result<Uint8List>> build({
    required ReportPeriod period,
    required ReportData data,
    required ({String revenue, String cost, String expenses, String profit})
    labels,
  }) => guard(() async {
    final company = await _company.load();
    final resolved = switch (company) {
      Success(:final value) => value,
      Failure(:final error) => throw StateError(error.message),
    };
    _fonts ??= await _loadFonts();
    int? change(Money current, Money previous) =>
        changePercent(current: current, previous: previous);
    return await ReportPdf.generate(
      ReportPdfData(
        company: resolved,
        from: period.from,
        to: period.to,
        kpis: [
          ReportPdfKpi(
            label: labels.revenue,
            value: data.kpis.revenue,
            changePercent: change(data.kpis.revenue, data.previous.revenue),
          ),
          ReportPdfKpi(
            label: labels.cost,
            value: data.kpis.cost,
            changePercent: change(data.kpis.cost, data.previous.cost),
          ),
          ReportPdfKpi(
            label: labels.expenses,
            value: data.kpis.expenses,
            changePercent: change(data.kpis.expenses, data.previous.expenses),
          ),
          ReportPdfKpi(
            label: labels.profit,
            value: data.kpis.profit,
            changePercent: change(data.kpis.profit, data.previous.profit),
          ),
        ],
        topProducts: [
          for (final p in data.products)
            ReportPdfProduct(name: p.name, sold: p.sold, revenue: p.revenue),
        ],
        expensesByCategory: [
          for (final c in data.categories)
            ReportPdfCategory(category: c.category, amount: c.net),
        ],
        drivers: [
          for (final d in data.drivers)
            ReportPdfDriver(
              name: d.name,
              tours: d.tours,
              revenue: d.revenue,
              averagePerTour: d.averagePerTour,
              returnRatePercent: d.returnRatePercent,
              differenceTotal: d.differenceSum,
            ),
        ],
      ),
      _fonts!,
    );
  });
}
