import 'dart:typed_data';

import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/pdf/pdf_file_name.dart';
import 'package:warenbestand/core/pdf/pdf_theme.dart';
import 'package:warenbestand/core/supabase/company_pdf_source.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/receipts/data/expenses_repository.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/features/receipts/pdf/expenses_month_pdf.dart';

/// Erzeugt die PDFs der Belege: ganzer Monat (Deckblatt, Übersicht, ein Beleg
/// pro Seite) oder ein einzelner Beleg. Nichts davon wird gespeichert; bei
/// Bedarf wird neu erzeugt.
final class ExpenseDocuments {
  ExpenseDocuments({
    required this._repository,
    required this._company,
    required this._loadFonts,
  });

  final ExpensesRepository _repository;
  final CompanyPdfSource _company;
  final Future<PdfFontBytes> Function() _loadFonts;
  PdfFontBytes? _fonts;

  static String monthFileName(int year, int month) =>
      PdfFileName.expensesMonth(year: year, month: month);

  static String singleFileName(Expense expense) =>
      PdfFileName.expense(date: expense.date, title: expense.title);

  /// Sammel-PDF eines Monats. Summen kommen aus der Datenbank.
  Future<Result<Uint8List>> month(int year, int month) => guard(() async {
    final expenses = _unwrap(await _repository.monthAll(year, month));
    final summary = _unwrap(await _repository.summary(year, month));
    final categories = _unwrap(await _repository.categories(year, month));
    final company = _unwrap(await _company.load());
    final items = await _items(expenses);
    return await _render(
      ExpensesMonthPdfData(
        company: company,
        year: year,
        month: month,
        items: items,
        net: summary.net,
        vat: summary.vat,
        gross: summary.gross,
        byCategory: [
          for (final c in categories)
            ExpenseCategoryTotal(category: c.category, gross: c.gross),
        ],
      ),
    );
  });

  /// Mehrere ausgewählte Belege als EIN PDF (mit Deckblatt und Summen der Auswahl).
  /// Die Beträge jedes Belegs kommen aus der Datenbank; hier werden nur die
  /// gewählten zusammengezählt.
  Future<Result<Uint8List>> selection(List<Expense> expenses) =>
      guard(() async {
        final sorted = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
        final company = _unwrap(await _company.load());
        final items = await _items(sorted);
        final byCategory = <String, Money>{};
        var net = Money.zero;
        var vat = Money.zero;
        var gross = Money.zero;
        for (final expense in sorted) {
          net += expense.net;
          vat += expense.vat;
          gross += expense.gross;
          byCategory[expense.category] =
              (byCategory[expense.category] ?? Money.zero) + expense.gross;
        }
        return await _render(
          ExpensesMonthPdfData(
            company: company,
            year: sorted.first.date.year,
            month: sorted.first.date.month,
            items: items,
            net: net,
            vat: vat,
            gross: gross,
            byCategory: [
              for (final entry in byCategory.entries)
                ExpenseCategoryTotal(category: entry.key, gross: entry.value),
            ],
          ),
        );
      });

  static String selectionFileName(List<Expense> expenses) {
    final dates = [for (final e in expenses) e.date]..sort();
    return PdfFileName.expensesSelection(from: dates.first, to: dates.last);
  }

  /// Ein einzelner Beleg als PDF (ohne Deckblatt).
  Future<Result<Uint8List>> single(Expense expense) => guard(() async {
    final company = _unwrap(await _company.load());
    final items = await _items([expense]);
    return await _render(
      ExpensesMonthPdfData(
        company: company,
        year: expense.date.year,
        month: expense.date.month,
        includeCover: false,
        items: items,
        net: expense.net,
        vat: expense.vat,
        gross: expense.gross,
        byCategory: [
          ExpenseCategoryTotal(
            category: expense.category,
            gross: expense.gross,
          ),
        ],
      ),
    );
  });

  Future<List<ExpensePdfItem>> _items(List<Expense> expenses) async {
    final photos = await Future.wait([
      for (final expense in expenses)
        if (expense.hasReceipt)
          _repository.downloadPhoto(expense.imagePath!)
        else
          Future.value(const Failure<Uint8List>(UnexpectedError())),
    ]);
    return [
      for (var i = 0; i < expenses.length; i++)
        ExpensePdfItem(
          date: expenses[i].date,
          title: expenses[i].title,
          category: expenses[i].category,
          vatRate: expenses[i].vatRate,
          net: expenses[i].net,
          gross: expenses[i].gross,
          image: photos[i] is Success<Uint8List>
              ? (photos[i] as Success<Uint8List>).value
              : null,
        ),
    ];
  }

  Future<Uint8List> _render(ExpensesMonthPdfData data) async {
    _fonts ??= await _loadFonts();
    return await ExpensesMonthPdf.generate(data, _fonts!);
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success(:final value) => value,
    Failure(:final error) => throw StateError(error.message),
  };
}
