import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/supabase/tenant_path.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';

/// Rechnungen, Positionen und die Rechnungs-Funktionen der Datenbank. Nummer,
/// Summen, Fälligkeit und Lagerbuchung berechnet die Datenbank; nach dem
/// Festschreiben ist nur noch `pdf_path` änderbar.
final class InvoicesRepository {
  const InvoicesRepository(this._client);

  static const pageSize = 25;

  final SupabaseClient _client;

  Future<Result<List<Invoice>>> list({
    required int page,
    String search = '',
    InvoiceFilter filter = InvoiceFilter.all,
  }) => guard(() async {
    var query = _client.from('invoices').select(Invoice.columns);
    switch (filter) {
      case InvoiceFilter.open:
        query = query.eq('status', 'open');
      case InvoiceFilter.paid:
        query = query.eq('status', 'paid');
      case InvoiceFilter.overdue:
        query = query.eq('status', 'overdue');
      case InvoiceFilter.draft:
        query = query.eq('status', 'draft');
      case InvoiceFilter.all:
        break;
    }
    final term = _escape(search);
    if (term.isNotEmpty) {
      query = query.or('recipient_name.ilike.%$term%,number.ilike.%$term%');
    }
    final rows = await query
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(Invoice.fromJson).toList(growable: false);
  });

  Future<Result<OpenInvoicesSummary>> summary() => guard(() async {
    final row = await _client
        .from('v_open_invoices')
        .select('open_gross_cents,open_count,overdue_count')
        .single();
    return OpenInvoicesSummary(
      openGross: Money((row['open_gross_cents'] as num).toInt()),
      openCount: (row['open_count'] as num).toInt(),
      overdueCount: (row['overdue_count'] as num).toInt(),
    );
  });

  Future<Result<Invoice>> getById(String id) => guard(() async {
    final row = await _client
        .from('invoices')
        .select(Invoice.columns)
        .eq('id', id)
        .single();
    return Invoice.fromJson(row);
  });

  Future<Result<List<InvoiceItem>>> items(String invoiceId) => guard(() async {
    final rows = await _client
        .from('invoice_items')
        .select(InvoiceItem.columns)
        .eq('invoice_id', invoiceId)
        .order('position', ascending: true);
    // Positionen stehen in der Reihenfolge der Produktliste; freie Positionen
    // am Ende.
    return sortByProductOrder(
      rows.map(InvoiceItem.fromJson),
      (item) => item.sortOrder,
    );
  });

  /// Nummer einer Rechnung (z. B. der stornierten), sonst `null`.
  Future<Result<String?>> numberOf(String invoiceId) => guard(() async {
    final row = await _client
        .from('invoices')
        .select('number')
        .eq('id', invoiceId)
        .maybeSingle();
    return row?['number'] as String?;
  });

  /// Zahlungsziel (Tage) und Kleinunternehmer-Kennzeichen aus den Firmendaten.
  Future<Result<({int termDays, bool smallBusiness})>> settings() =>
      guard(() async {
        final row = await _client
            .from('company_settings')
            .select('payment_term_days,is_small_business')
            .single();
        return (
          termDays: row['payment_term_days'] as int,
          smallBusiness: row['is_small_business'] as bool,
        );
      });

  /// Produkte zu den angegebenen IDs (für das Bearbeiten eines Entwurfs).
  Future<Result<List<InvoiceProduct>>> productsByIds(List<String> ids) =>
      guard(() async {
        if (ids.isEmpty) return <InvoiceProduct>[];
        final rows = await _client
            .from('products')
            .select(InvoiceProduct.columns)
            .inFilter('id', ids);
        return rows.map(InvoiceProduct.fromJson).toList(growable: false);
      });

  Future<Result<List<InvoiceProduct>>> products({String search = ''}) =>
      guard(() async {
        var query = _client
            .from('products')
            .select(InvoiceProduct.columns)
            .eq('active', true);
        final term = _escape(search);
        if (term.isNotEmpty) {
          query = query.or(
            'name.ilike.%$term%,name_ar.ilike.%$term%,sku.ilike.%$term%',
          );
        }
        final rows = await query
            .order('sort_order', ascending: true)
            .order('name', ascending: true)
            .limit(500);
        return rows.map(InvoiceProduct.fromJson).toList(growable: false);
      });

  /// Entwurf mit Positionen anlegen; gibt die ID zurück. Schlagen die
  /// Positionen fehl, wird der neue Entwurf wieder gelöscht.
  Future<Result<String>> create(InvoiceInput input) => guard(() async {
    final row = await _client
        .from('invoices')
        .insert(_header(input))
        .select('id')
        .single();
    final id = row['id'] as String;
    try {
      await _insertItems(id, input.lines);
    } on Object {
      await _client.from('invoices').delete().eq('id', id);
      rethrow;
    }
    return id;
  });

  Future<Result<void>> updateDraft(String id, InvoiceInput input) =>
      guard(() async {
        await _client.from('invoices').update(_header(input)).eq('id', id);
        await _client.from('invoice_items').delete().eq('invoice_id', id);
        await _insertItems(id, input.lines);
      });

  /// Löscht eine Rechnung in jedem Zustand (auch festgeschrieben).
  Future<Result<void>> deleteDraft(String id) => guard(() async {
    await _client.rpc<void>('delete_invoice', params: {'p_invoice_id': id});
  });

  /// Festschreiben; gibt die vergebene Rechnungsnummer zurück.
  Future<Result<String>> finalize(String id) => guard(() async {
    final number = await _client.rpc<String>(
      'finalize_invoice',
      params: {'p_invoice_id': id},
    );
    return number;
  });

  /// Stornieren (nur Chef); gibt die ID der Stornorechnung zurück.
  Future<Result<String>> cancel(String id) => guard(() async {
    final result = await _client.rpc<String>(
      'cancel_invoice',
      params: {'p_invoice_id': id},
    );
    return result;
  });

  Future<Result<void>> markPaid(String id) => guard(() async {
    await _client.rpc<void>('mark_invoice_paid', params: {'p_invoice_id': id});
  });

  Future<Result<void>> markUnpaid(String id) => guard(() async {
    await _client.rpc<void>(
      'mark_invoice_unpaid',
      params: {'p_invoice_id': id},
    );
  });

  Future<Result<Uint8List>> downloadPdf(String path) =>
      guard(() => _client.storage.from('documents').download(path));

  /// Legt das PDF der festgeschriebenen Rechnung ab und merkt den Pfad.
  Future<Result<void>> storePdf({
    required String invoiceId,
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
        .from('invoices')
        .update({'pdf_path': fullPath})
        .eq('id', invoiceId);
  });

  Map<String, Object?> _header(InvoiceInput input) => {
    'recipient_name': input.recipientName.trim(),
    'recipient_address': input.recipientAddress.trim(),
    'recipient_vat_id': _nullable(input.recipientVatId),
    'date': DateFormatter.iso(input.date),
    'service_date': DateFormatter.iso(input.serviceDate),
    'due_date': DateFormatter.iso(input.dueDate),
    'note': _nullable(input.note),
  };

  Future<void> _insertItems(String id, List<InvoiceDraftLine> lines) async {
    if (lines.isEmpty) return;
    await _client.from('invoice_items').insert([
      for (var i = 0; i < lines.length; i++)
        {
          'invoice_id': id,
          'position': i + 1,
          'qty': lines[i].quantity.base,
          'price_net_cents': lines[i].priceNet.cents,
          // Alle Zeilen haben dieselben Schlüssel (Voraussetzung für Sammel-
          // inserts). Bei Produkten überschreibt die Datenbank Name, Einheit
          // und USt aus dem Produkt.
          'product_id': lines[i].productId,
          'product_name': lines[i].isFree ? lines[i].name.trim() : null,
          'unit': lines[i].isFree ? lines[i].quantity.unit.dbValue : null,
          'vat_rate': lines[i].isFree ? lines[i].vatRate.percent : null,
        },
    ]);
  }

  String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _escape(String input) =>
      input.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
}
