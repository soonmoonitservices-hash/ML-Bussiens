import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';

/// Touren, Positionen und die Tour-Funktionen der Datenbank. Name, Einheit und
/// Preise der Positionen kopiert die Datenbank; Start und Rücknahme buchen das
/// Lager in einer Transaktion.
final class ToursRepository {
  const ToursRepository(this._client);

  static const pageSize = 25;

  final SupabaseClient _client;

  Future<Result<List<Tour>>> list({
    required int page,
    required TourStatus status,
    String search = '',
  }) => guard(() async {
    var query = _client
        .from('v_tour_overview')
        .select(Tour.columns)
        .eq('status', status.dbValue);
    final term = search.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
    if (term.isNotEmpty) {
      query = query.or('driver_name.ilike.%$term%,number.ilike.%$term%');
    }
    final rows = await query
        .order('planned_at', ascending: status != TourStatus.closed)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(Tour.fromJson).toList(growable: false);
  });

  Future<Result<Tour>> getById(String id) => guard(() async {
    final row = await _client
        .from('v_tour_overview')
        .select(Tour.columns)
        .eq('id', id)
        .single();
    return Tour.fromJson(row);
  });

  Future<Result<List<TourItem>>> items(String tourId) => guard(() async {
    final rows = await _client
        .from('tour_items')
        .select('${TourItem.columns},products(sort_order)')
        .eq('tour_id', tourId);
    // Reihenfolge wie in der Produktliste (eigene Sortierung), nicht nach Name.
    return sortByProductOrder(
      rows,
      (row) =>
          (row['products'] as Map<String, dynamic>?)?['sort_order'] as int?,
    ).map(TourItem.fromJson).toList(growable: false);
  });

  /// Ladung eines Entwurfs als Auswahlzeilen mit aktuellem Bestand und
  /// aktuellen Preisen (beim Start werden die Preise ohnehin neu kopiert).
  Future<Result<List<LoadItem>>> draftLoad(String tourId) => guard(() async {
    final rows = await _client
        .from('tour_items')
        .select('product_id,loaded_qty')
        .eq('tour_id', tourId);
    if (rows.isEmpty) return <LoadItem>[];
    final ids = rows.map((row) => row['product_id'] as String).toList();
    final products = await _client
        .from('products')
        .select(TourProduct.columns)
        .inFilter('id', ids);
    final byId = {
      for (final row in products)
        row['id'] as String: TourProduct.fromJson(row),
    };
    // Reihenfolge wie in der Produktliste.
    return sortByProductOrder([
      for (final row in rows)
        if (byId[row['product_id']] case final product?)
          LoadItem(
            product: product,
            quantity: Quantity(row['loaded_qty'] as int, product.unit),
          ),
    ], (item) => item.product.sortOrder);
  });

  /// Aktive Produkte zum Beladen, mit Suche.
  Future<Result<List<TourProduct>>> products({String search = ''}) =>
      guard(() async {
        var query = _client
            .from('products')
            .select(TourProduct.columns)
            .eq('active', true);
        final term = search.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
        if (term.isNotEmpty) {
          query = query.or(
            'name.ilike.%$term%,name_ar.ilike.%$term%,sku.ilike.%$term%',
          );
        }
        final rows = await query
            .order('sort_order', ascending: true)
            .order('name', ascending: true)
            .limit(500);
        return rows.map(TourProduct.fromJson).toList(growable: false);
      });

  /// Aktive Produkte zu den angegebenen IDs.
  Future<Result<List<TourProduct>>> productsByIds(List<String> ids) =>
      guard(() async {
        if (ids.isEmpty) return <TourProduct>[];
        final rows = await _client
            .from('products')
            .select(TourProduct.columns)
            .eq('active', true)
            .inFilter('id', ids);
        return rows.map(TourProduct.fromJson).toList(growable: false);
      });

  /// Aktive Fahrer zur Auswahl.
  Future<Result<List<TourDriver>>> drivers({String search = ''}) =>
      guard(() async {
        var query = _client
            .from('drivers')
            .select('id,name,vehicle')
            .eq('active', true);
        final term = search.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
        if (term.isNotEmpty) query = query.ilike('name', '%$term%');
        final rows = await query.order('name').limit(50);
        return rows.map(TourDriver.fromJson).toList(growable: false);
      });

  /// Legt einen Entwurf mit Positionen an. Schlägt das Anlegen der Positionen
  /// fehl, wird die neue Tour wieder gelöscht.
  Future<Result<String>> createDraft({
    required String driverId,
    required DateTime plannedAt,
    required String? name,
    required List<LoadItem> items,
  }) => guard(() async {
    final tour = await _client
        .from('tours')
        .insert({
          'driver_id': driverId,
          'planned_at': plannedAt.toUtc().toIso8601String(),
          'name': _nullable(name),
        })
        .select('id')
        .single();
    final id = tour['id'] as String;
    try {
      await _insertItems(id, items);
    } on Object {
      await _client.from('tours').delete().eq('id', id);
      rethrow;
    }
    return id;
  });

  /// Ersetzt Kopfdaten und Positionen eines Entwurfs.
  Future<Result<void>> updateDraft({
    required String tourId,
    required String driverId,
    required DateTime plannedAt,
    required String? name,
    required List<LoadItem> items,
  }) => guard(() async {
    await _client
        .from('tours')
        .update({
          'driver_id': driverId,
          'planned_at': plannedAt.toUtc().toIso8601String(),
          'name': _nullable(name),
        })
        .eq('id', tourId);
    await _client.from('tour_items').delete().eq('tour_id', tourId);
    await _insertItems(tourId, items);
  });

  /// Löscht eine Tour in jedem Zustand (mit Positionen und Tour-Ausgaben).
  Future<Result<void>> deleteDraft(String tourId) => guard(() async {
    await _client.rpc<void>('delete_tour', params: {'p_tour_id': tourId});
  });

  Future<Result<List<TourExpense>>> expenses(String tourId) => guard(() async {
    final rows = await _client
        .from('expenses')
        .select(TourExpense.columns)
        .eq('tour_id', tourId)
        .order('created_at');
    return rows.map(TourExpense.fromJson).toList(growable: false);
  });

  Future<Result<void>> addExpense(String tourId, TourExpenseInput input) =>
      guard(() async {
        await _client.from('expenses').insert({
          'tour_id': tourId,
          'title': input.title,
          'category': input.category,
          'gross_cents': input.gross.cents,
          'vat_rate': input.vatRate.percent,
        });
      });

  Future<Result<void>> deleteExpense(String expenseId) => guard(() async {
    await _client.from('expenses').delete().eq('id', expenseId);
  });

  /// Ob der Fahrer Bruttopreise kassiert (Einstellung der Firma).
  Future<Result<bool>> cashIncludesVat() => guard(() async {
    final row = await _client
        .from('company_settings')
        .select('cash_includes_vat')
        .single();
    return row['cash_includes_vat'] as bool;
  });

  /// Aus Kartons entfernte Produkte einer abgeschlossenen Tour.
  Future<Result<List<TourRemovalRow>>> removals(String tourId) =>
      guard(() async {
        final rows = await _client
            .from('tour_item_removals')
            .select(TourRemovalRow.columns)
            .eq('tour_items.tour_id', tourId);
        return rows.map(TourRemovalRow.fromJson).toList(growable: false);
      });

  /// Inhalt der Kartons (je Karton-Produkt die enthaltenen Produkte mit Preisen).
  Future<Result<Map<String, List<TourContent>>>> cartonContents(
    List<String> cartonIds,
  ) => guard(() async {
    if (cartonIds.isEmpty) return <String, List<TourContent>>{};
    final rows = await _client
        .from('product_contents')
        .select(TourContent.columns)
        .inFilter('product_id', cartonIds);
    final map = <String, List<TourContent>>{};
    for (final row in rows) {
      final content = TourContent.fromJson(row);
      map.putIfAbsent(content.cartonId, () => []).add(content);
    }
    return map;
  });

  /// Schließt die Tour ab. [returns] enthält je Produkt die zurückgebrachte
  /// Menge in Basiseinheit; die Datenbank prüft, bucht und friert ein.
  Future<Result<void>> close({
    required String tourId,
    required Map<String, int> returns,
    required int cashReceivedCents,
    Map<String, int> gifts = const {},
    Map<String, Map<String, CartonRemoval>> removals = const {},
    String? differenceReason,
  }) => guard(() async {
    await _client.rpc<void>(
      'close_tour',
      params: {
        'p_tour_id': tourId,
        'p_returns': [
          for (final entry in returns.entries)
            {
              'product_id': entry.key,
              'returned_qty': entry.value,
              'gift_qty': gifts[entry.key] ?? 0,
              if ((removals[entry.key] ?? const {}).values.any(
                (r) => !r.isEmpty,
              ))
                'removals': [
                  for (final removal in removals[entry.key]!.entries)
                    if (!removal.value.isEmpty)
                      {
                        'product_id': removal.key,
                        'returned_qty': removal.value.returned.base,
                        'gift_qty': removal.value.gift.base,
                      },
                ],
            },
        ],
        'p_cash_received_cents': cashReceivedCents,
        'p_difference_reason': (differenceReason?.trim().isEmpty ?? true)
            ? null
            : differenceReason!.trim(),
      },
    );
  });

  Future<Result<void>> start(String tourId) => _call('start_tour', tourId);

  Future<Result<void>> undoStart(String tourId) =>
      _call('undo_start_tour', tourId);

  Future<Result<void>> reopen(String tourId) => _call('reopen_tour', tourId);

  Future<Result<void>> _call(String function, String tourId) => guard(() async {
    await _client.rpc<void>(function, params: {'p_tour_id': tourId});
  });

  Future<void> _insertItems(String tourId, List<LoadItem> items) async {
    if (items.isEmpty) return;
    await _client.from('tour_items').insert([
      for (final item in items)
        {
          'tour_id': tourId,
          'product_id': item.product.id,
          'loaded_qty': item.quantity.base,
        },
    ]);
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
