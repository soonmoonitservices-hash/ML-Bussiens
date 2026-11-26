import 'dart:typed_data';

import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/tours/domain/goods_list.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/features/tours/pdf/goods_list_pdf.dart';
import 'package:warenbestand/features/tours/pdf/tour_summary_pdf.dart';

/// Erzeugt das PDF der Warenlisten einer Tour („Verkaufte Ware“,
/// „Zurückgeholte Ware“). Wird nicht gespeichert, bei Bedarf neu erzeugt.
final class TourGoodsDocuments {
  TourGoodsDocuments({required this._company, required this._loadFonts});

  final CompanyPdfSource _company;
  final Future<PdfFontBytes> Function() _loadFonts;
  PdfFontBytes? _fonts;

  static String fileName(GoodsListKind kind, String tourNumber) =>
      PdfFileName.goodsList(
        title: kind == GoodsListKind.sold
            ? 'Verkaufte Ware'
            : 'Zurückgeholte Ware',
        tourNumber: tourNumber,
      );

  static String summaryFileName(String tourNumber) =>
      PdfFileName.goodsList(title: 'Tourabrechnung', tourNumber: tourNumber);

  /// Tourabrechnung einer abgeschlossenen Tour. Alle Summen kommen aus der
  /// Datenbank (eingefrorene Werte der Tour).
  Future<Result<Uint8List>> summary({
    required Tour tour,
    required List<TourItem> items,
    required List<TourExpense> expenses,
  }) => guard(() async {
    final companyResult = await _company.load();
    final company = switch (companyResult) {
      Success(:final value) => value,
      Failure(:final error) => throw StateError(error.message),
    };
    _fonts ??= await _loadFonts();
    return await TourSummaryPdf.generate(
      TourSummaryPdfData(
        company: company,
        tourNumber: tour.number ?? '',
        driverName: tour.driverName,
        date: tour.plannedAt,
        startedAt: tour.startedAt,
        closedAt: tour.closedAt,
        lines: [
          for (final item in items)
            TourPdfLine(
              name: item.name,
              loaded: item.loaded,
              returned: item.returned,
              gift: item.giftQty,
              sellPrice: item.sellPrice,
              revenue: item.sold.valueAt(item.sellPrice) - item.removedRevenue,
            ),
        ],
        expenses: [
          for (final e in expenses)
            TourPdfExpense(title: e.title, gross: e.gross),
        ],
        revenue: tour.revenueNet ?? Money.zero,
        expensesGross: tour.expensesGross ?? Money.zero,
        expectedCash: tour.expectedCash ?? Money.zero,
        cashReceived: tour.cashReceived ?? Money.zero,
        difference: tour.difference ?? Money.zero,
        differenceReason: tour.differenceReason,
        cost: tour.cost ?? Money.zero,
        profit: tour.profit ?? Money.zero,
      ),
      _fonts!,
    );
  });

  Future<Result<Uint8List>> build({
    required GoodsListKind kind,
    required String tourNumber,
    required String driverName,
    required DateTime date,
    required List<GoodsLine> lines,
  }) => guard(() async {
    final companyResult = await _company.load();
    final company = switch (companyResult) {
      Success(:final value) => value,
      Failure(:final error) => throw StateError(error.message),
    };
    _fonts ??= await _loadFonts();
    return await GoodsListPdf.generate(
      GoodsListPdfData(
        company: company,
        kind: kind,
        tourNumber: tourNumber,
        driverName: driverName,
        date: date,
        lines: lines,
        total: GoodsLists.total(lines),
      ),
      _fonts!,
    );
  });
}
