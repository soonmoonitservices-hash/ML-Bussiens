import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/tenant_path.dart';
import 'package:warenbestand/features/products/domain/product.dart';

/// Zugriff auf `products` (Liste, Anlegen, Ändern, Fotos).
final class ProductsRepository {
  const ProductsRepository(this._client);

  static const pageSize = 25;

  final SupabaseClient _client;

  Future<Result<Product>> getById(String id) => guard(() async {
    final row = await _client
        .from('products')
        .select(Product.columns)
        .eq('id', id)
        .single();
    return Product.fromJson(row);
  });

  Future<Result<Product>> create(ProductInput input) => guard(() async {
    final row = await _client
        .from('products')
        .insert(input.toJson(creating: true))
        .select(Product.columns)
        .single();
    return Product.fromJson(row);
  });

  /// Ändert nur, wenn niemand das Produkt seit dem Laden geändert hat.
  Future<Result<Product>> update({
    required String id,
    required DateTime loadedUpdatedAt,
    required ProductInput input,
  }) => guard(() async {
    final rows = await _client
        .from('products')
        .update(input.toJson(creating: false))
        .eq('id', id)
        .eq('updated_at', loadedUpdatedAt.toUtc().toIso8601String())
        .select(Product.columns);
    if (rows.isEmpty) {
      throw ConflictException(await _lastEditorName(id));
    }
    return Product.fromJson(rows.single);
  });

  Future<Result<Product>> setActive(Product product, {required bool active}) =>
      guard(() async {
        final rows = await _client
            .from('products')
            .update({'active': active})
            .eq('id', product.id)
            .eq('updated_at', product.updatedAt.toUtc().toIso8601String())
            .select(Product.columns);
        if (rows.isEmpty) {
          throw ConflictException(await _lastEditorName(product.id));
        }
        return Product.fromJson(rows.single);
      });

  /// Produktliste mit Suche, Filter und Kategorie (25 pro Seite).
  Future<Result<List<Product>>> list({
    required int page,
    String search = '',
    ProductFilter filter = ProductFilter.all,
    String? category,
  }) => guard(() async {
    var query = _client
        .from('products')
        .select(Product.columns)
        .eq('active', filter != ProductFilter.inactive);
    if (category != null) query = query.eq('category', category);
    final term = search.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
    if (term.isNotEmpty) {
      query = query.or(
        'name.ilike.%$term%,name_ar.ilike.%$term%,sku.ilike.%$term%',
      );
    }
    final rows = await query
        .order('sort_order', ascending: true)
        .order('name', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    return rows.map(Product.fromJson).toList(growable: false);
  });

  /// Alle aktiven Produkte in der gespeicherten Reihenfolge (für den
  /// Reihenfolge-Modus; lädt in Blöcken von 100, bis alles da ist).
  Future<Result<List<Product>>> allActive() => guard(() async {
    const block = 100;
    final all = <Product>[];
    for (var page = 0; ; page++) {
      final rows = await _client
          .from('products')
          .select(Product.columns)
          .eq('active', true)
          .order('sort_order', ascending: true)
          .order('name', ascending: true)
          .range(page * block, (page + 1) * block - 1);
      all.addAll(rows.map(Product.fromJson));
      if (rows.length < block) return all;
    }
  });

  /// Speichert die eigene Reihenfolge. [ids] steht in der neuen Reihenfolge;
  /// Produkte außerhalb der Liste behalten ihren Platz (Funktion in der DB).
  Future<Result<void>> reorder(List<String> ids) => guard(() async {
    await _client.rpc<void>('reorder_products', params: {'p_ids': ids});
  });

  /// Inhalt eines Kartons (Produkte mit Menge je Karton).
  Future<Result<List<ProductContent>>> contents(String productId) =>
      guard(() async {
        final rows = await _client
            .from('product_contents')
            .select(ProductContent.columns)
            .eq('product_id', productId);
        return rows.map(ProductContent.fromJson).toList(growable: false);
      });

  /// Ersetzt den Inhalt eines Kartons (leere Liste = kein Inhalt).
  Future<Result<void>> saveContents(
    String productId,
    List<ProductContent> lines,
  ) => guard(() async {
    await _client.from('product_contents').delete().eq('product_id', productId);
    if (lines.isEmpty) return;
    await _client.from('product_contents').insert([
      for (final line in lines)
        {
          'product_id': productId,
          'content_product_id': line.productId,
          'qty': line.quantity.base,
        },
    ]);
  });

  /// Aktive Produkte, die in einen Karton passen (keine Kartons), mit Suche.
  Future<Result<List<Product>>> pickable({String search = ''}) =>
      guard(() async {
        var query = _client
            .from('products')
            .select(Product.columns)
            .eq('active', true)
            .neq('unit', 'carton');
        final term = search.trim().replaceAll(RegExp('[%,()*]'), ' ').trim();
        if (term.isNotEmpty) {
          query = query.or('name.ilike.%$term%,name_ar.ilike.%$term%');
        }
        final rows = await query
            .order('sort_order', ascending: true)
            .order('name', ascending: true)
            .limit(50);
        return rows.map(Product.fromJson).toList(growable: false);
      });

  /// Anzahl aktiver Produkte.
  Future<Result<int>> activeCount() => guard(() async {
    final rows = await _client.from('products').select('id').eq('active', true);
    return rows.length;
  });

  /// Kategorien aktiver Produkte, alphabetisch, ohne Leere.
  Future<Result<List<String>>> categories() => guard(() async {
    final rows = await _client
        .from('products')
        .select('category')
        .eq('active', true);
    final set = <String>{
      for (final row in rows)
        if ((row['category'] as String).trim().isNotEmpty)
          (row['category'] as String).trim(),
    };
    return set.toList()..sort();
  });

  /// Legt ein verkleinertes Produktfoto im Bucket `products` ab; gibt den Pfad
  /// zurück.
  Future<Result<String>> uploadPhoto(Uint8List jpeg) => guard(() async {
    final path = await tenantPath(
      _client,
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await _client.storage
        .from('products')
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
      guard(() => _client.storage.from('products').download(path));

  Future<String?> _lastEditorName(String id) async {
    final product = await _client
        .from('products')
        .select('updated_by')
        .eq('id', id)
        .maybeSingle();
    final userId = product?['updated_by'] as String?;
    if (userId == null) return null;
    final profile = await _client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
    return profile?['name'] as String?;
  }
}
