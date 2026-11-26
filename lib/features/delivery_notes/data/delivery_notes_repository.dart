import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/supabase/tenant_path.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';

/// Lieferscheine, Positionen und Dateien (Unterschrift, PDF). Nummer vergibt
/// die Datenbank; nach der Unterschrift ist der Lieferschein gesperrt.
final class DeliveryNotesRepository {
  const DeliveryNotesRepository(this._client);

  static const pageSize = 25;

  final SupabaseClient _client;

  Future<Result<List<DeliveryNote>>> list({
    required int page,
    String search = '',
    DeliveryFilter filter = DeliveryFilter.all,
  }) => guard(() async {
    var query = _client.from('delivery_notes').select(DeliveryNote.columns);
    switch (filter) {
      case DeliveryFilter.signed:
        query = query.not('signed_at', 'is', null);
      case DeliveryFilter.open:
        query = query.isFilter('signed_at', null);
      case DeliveryFilter.all:
        break;
    }
    final term = _escape(search);
    if (term.isNotEmpty) {
      query = query.or('recipient_name.ilike.%$term%,number.ilike.%$term%');
    }
    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(DeliveryNote.fromJson).toList(growable: false);
  });

  Future<Result<DeliveryNote>> getById(String id) => guard(() async {
    final row = await _client
        .from('delivery_notes')
        .select(DeliveryNote.columns)
        .eq('id', id)
        .single();
    return DeliveryNote.fromJson(row);
  });

  Future<Result<List<DeliveryNoteItem>>> items(String id) => guard(() async {
    final rows = await _client
        .from('delivery_note_items')
        .select(DeliveryNoteItem.columns)
        .eq('delivery_note_id', id)
        .order('position', ascending: true);
    // Positionen stehen in der Reihenfolge der Produktliste.
    return sortByProductOrder(
      rows.map(DeliveryNoteItem.fromJson),
      (item) => item.sortOrder,
    );
  });

  /// Lieferschein mit Positionen anlegen; gibt die ID zurück. Schlagen die
  /// Positionen fehl, wird der neue Lieferschein wieder gelöscht.
  Future<Result<String>> create(DeliveryNoteInput input) => guard(() async {
    final row = await _client
        .from('delivery_notes')
        .insert(_header(input))
        .select('id')
        .single();
    final id = row['id'] as String;
    try {
      await _insertItems(id, input.items);
    } on Object {
      await _client.from('delivery_notes').delete().eq('id', id);
      rethrow;
    }
    return id;
  });

  Future<Result<void>> updateDraft(String id, DeliveryNoteInput input) => guard(
    () async {
      await _client.from('delivery_notes').update(_header(input)).eq('id', id);
      await _client
          .from('delivery_note_items')
          .delete()
          .eq('delivery_note_id', id);
      await _insertItems(id, input.items);
    },
  );

  /// Löscht einen Lieferschein (auch unterschrieben).
  Future<Result<void>> delete(String id) => guard(() async {
    await _client.rpc<void>(
      'delete_delivery_note',
      params: {'p_delivery_note_id': id},
    );
  });

  Future<Result<List<DeliveryProduct>>> products({String search = ''}) =>
      guard(() async {
        var query = _client
            .from('products')
            .select(DeliveryProduct.columns)
            .eq('active', true);
        final term = _escape(search);
        if (term.isNotEmpty) {
          query = query.or('name.ilike.%$term%,sku.ilike.%$term%');
        }
        final rows = await query
            .order('sort_order', ascending: true)
            .order('name', ascending: true)
            .limit(500);
        return rows.map(DeliveryProduct.fromJson).toList(growable: false);
      });

  Future<Result<List<DeliveryTour>>> tours() => guard(() async {
    final rows = await _client
        .from('tours')
        .select('id,number,driver_name,planned_at')
        .neq('status', 'draft')
        .order('planned_at', ascending: false)
        .limit(30);
    return rows.map(DeliveryTour.fromJson).toList(growable: false);
  });

  /// Positionen einer Tour als Lieferscheinpositionen (geladene Mengen).
  Future<Result<List<DeliveryDraftItem>>> tourItems(String tourId) =>
      guard(() async {
        final rows = await _client
            .from('tour_items')
            .select('product_id,loaded_qty')
            .eq('tour_id', tourId);
        if (rows.isEmpty) return <DeliveryDraftItem>[];
        final ids = rows.map((row) => row['product_id'] as String).toList();
        final products = await _client
            .from('products')
            .select(DeliveryProduct.columns)
            .inFilter('id', ids);
        final byId = {
          for (final row in products)
            row['id'] as String: DeliveryProduct.fromJson(row),
        };
        // Reihenfolge wie in der Produktliste.
        return sortByProductOrder([
          for (final row in rows)
            if (byId[row['product_id']] case final product?)
              DeliveryDraftItem(
                product: product,
                quantity: Quantity(row['loaded_qty'] as int, product.unit),
              ),
        ], (item) => item.product.sortOrder);
      });

  /// Produkte zu den angegebenen IDs (für das Bearbeiten eines Entwurfs).
  Future<Result<List<DeliveryProduct>>> productsByIds(List<String> ids) =>
      guard(() async {
        if (ids.isEmpty) return <DeliveryProduct>[];
        final rows = await _client
            .from('products')
            .select(DeliveryProduct.columns)
            .inFilter('id', ids);
        return rows.map(DeliveryProduct.fromJson).toList(growable: false);
      });

  /// Unterschreiben: Bild ablegen, dann Name und Unterschrift am Lieferschein
  /// setzen. Die Datenbank prüft Positionen, Name und Bild und setzt die Zeit.
  Future<Result<void>> sign({
    required DeliveryNote note,
    required Uint8List signaturePng,
    required String signerName,
  }) => guard(() async {
    final path = await tenantPath(
      _client,
      '${note.date.year}/${note.number}.png',
    );
    await _client.storage
        .from('signatures')
        .uploadBinary(
          path,
          signaturePng,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            cacheControl: '31536000',
          ),
        );
    await _client
        .from('delivery_notes')
        .update({
          'signature_path': path,
          'signer_name': signerName.trim(),
          'signed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', note.id);
  });

  Future<Result<Uint8List>> downloadSignature(String path) =>
      guard(() => _client.storage.from('signatures').download(path));

  Future<Result<Uint8List>> downloadPdf(String path) =>
      guard(() => _client.storage.from('documents').download(path));

  /// Legt das PDF des unterschriebenen Lieferscheins ab und merkt den Pfad.
  Future<Result<void>> storePdf({
    required DeliveryNote note,
    required String path,
    required Uint8List pdf,
  }) => guard(() async {
    final fullPath = await tenantPath(_client, path);
    await _client.storage
        .from('documents')
        .uploadBinary(
          fullPath,
          pdf,
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );
    await _client
        .from('delivery_notes')
        .update({'pdf_path': fullPath})
        .eq('id', note.id);
  });

  /// Neue Entwurfsrechnung aus dem Lieferschein; gibt die Rechnungs-ID zurück.
  Future<Result<String>> invoiceFromNote(String id) => guard(() async {
    final result = await _client.rpc<String>(
      'invoice_from_delivery_note',
      params: {'p_delivery_note_id': id},
    );
    return result;
  });

  Map<String, Object?> _header(DeliveryNoteInput input) => {
    'recipient_name': input.recipientName.trim(),
    'recipient_address': input.recipientAddress.trim(),
    'date': DateFormatter.iso(input.date),
    'tour_id': input.tourId,
    'note': (input.note?.trim().isEmpty ?? true) ? null : input.note!.trim(),
  };

  Future<void> _insertItems(String id, List<DeliveryDraftItem> items) async {
    if (items.isEmpty) return;
    await _client.from('delivery_note_items').insert([
      for (var i = 0; i < items.length; i++)
        {
          'delivery_note_id': id,
          'product_id': items[i].product.id,
          'qty': items[i].quantity.base,
          'position': i + 1,
        },
    ]);
  }

  String _escape(String input) =>
      input.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
}
