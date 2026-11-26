import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/supabase/tenant_path.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';

/// Ausgaben und Belege (Tabelle `expenses`, Bucket `receipts`). Tour-Ausgaben
/// sind Ausgaben mit `tour_id`; die von abgeschlossenen Touren sind gesperrt.
final class ExpensesRepository {
  const ExpensesRepository(this._client);

  static const pageSize = 30;

  final SupabaseClient _client;

  static String _yearMonth(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  Future<Result<List<Expense>>> month({
    required int year,
    required int month,
    required ExpenseFilter filter,
    required int page,
  }) => guard(() async {
    var query = _client
        .from('expenses')
        .select(Expense.columns)
        .eq('year_month', _yearMonth(year, month));
    switch (filter) {
      case ExpenseFilter.tour:
        query = query.not('tour_id', 'is', null);
      case ExpenseFilter.other:
        query = query.isFilter('tour_id', null);
      case ExpenseFilter.all:
        break;
    }
    final rows = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(Expense.fromJson).toList(growable: false);
  });

  /// Alle Belege eines Monats für das Sammel-PDF, nach Datum aufsteigend.
  Future<Result<List<Expense>>> monthAll(int year, int month) =>
      guard(() async {
        final rows = await _client
            .from('expenses')
            .select(Expense.columns)
            .eq('year_month', _yearMonth(year, month))
            .order('date')
            .order('created_at');
        return rows.map(Expense.fromJson).toList(growable: false);
      });

  Future<Result<MonthSummary>> summary(int year, int month) => guard(() async {
    final row = await _client
        .from('v_expenses_by_month')
        .select('expense_count,gross_cents,net_cents,vat_cents')
        .eq('year_month', _yearMonth(year, month))
        .maybeSingle();
    if (row == null) return MonthSummary.empty;
    return MonthSummary(
      count: (row['expense_count'] as num).toInt(),
      gross: Money((row['gross_cents'] as num).toInt()),
      net: Money((row['net_cents'] as num).toInt()),
      vat: Money((row['vat_cents'] as num).toInt()),
    );
  });

  /// Summen je Kategorie im Monat (Funktion der Datenbank).
  Future<Result<List<CategorySum>>> categories(int year, int month) =>
      guard(() async {
        final from = DateTime(year, month);
        final to = DateTime(year, month + 1).subtract(const Duration(days: 1));
        final rows = await _client.rpc<List<dynamic>>(
          'report_expenses_by_category',
          params: {
            'p_from': DateFormatter.iso(from),
            'p_to': DateFormatter.iso(to),
          },
        );
        return [
          for (final row in rows.cast<Map<String, dynamic>>())
            CategorySum(
              category: row['category'] as String,
              gross: Money((row['gross_cents'] as num).toInt()),
            ),
        ];
      });

  Future<Result<Expense>> getById(String id) => guard(() async {
    final row = await _client
        .from('expenses')
        .select(Expense.columns)
        .eq('id', id)
        .single();
    return Expense.fromJson(row);
  });

  Future<Result<void>> create(ExpenseInput input) => guard(() async {
    await _client.from('expenses').insert(_json(input));
  });

  /// Ändert nur, wenn niemand die Ausgabe seit dem Laden geändert hat.
  Future<Result<void>> update(Expense loaded, ExpenseInput input) =>
      guard(() async {
        final rows = await _client
            .from('expenses')
            .update(_json(input))
            .eq('id', loaded.id)
            .eq('updated_at', loaded.updatedAt.toUtc().toIso8601String())
            .select('id');
        if (rows.isEmpty) throw const ConflictException(null);
      });

  Future<Result<void>> delete(String id) => guard(() async {
    await _client.from('expenses').delete().eq('id', id);
  });

  Future<Result<List<ExpenseTour>>> tours() => guard(() async {
    final rows = await _client
        .from('tours')
        .select('id,number,driver_name')
        .neq('status', 'draft')
        .order('planned_at', ascending: false)
        .limit(30);
    return rows.map(ExpenseTour.fromJson).toList(growable: false);
  });

  /// Legt ein Belegfoto im Bucket `receipts` ab (Ordner = Monat) und gibt den
  /// Pfad zurück.
  Future<Result<String>> uploadPhoto(Uint8List jpeg, DateTime date) =>
      guard(() async {
        final folder = _yearMonth(date.year, date.month);
        final name = DateTime.now().microsecondsSinceEpoch;
        final path = await tenantPath(_client, '$folder/$name.jpg');
        await _client.storage
            .from('receipts')
            .uploadBinary(
              path,
              jpeg,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                cacheControl: '31536000',
              ),
            );
        return path;
      });

  Future<Result<Uint8List>> downloadPhoto(String path) =>
      guard(() => _client.storage.from('receipts').download(path));

  Map<String, Object?> _json(ExpenseInput input) => {
    'date': DateFormatter.iso(input.date),
    'title': input.title.trim(),
    'category': input.category,
    'gross_cents': input.gross.cents,
    'vat_rate': input.vatRate.percent,
    'tour_id': input.tourId,
    'note': (input.note?.trim().isEmpty ?? true) ? null : input.note!.trim(),
    'image_path': input.imagePath,
  };
}
