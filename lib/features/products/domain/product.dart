import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Ein Produkt (Zeile aus `products`). Preise pro Basiseinheit, bei kg pro
/// Kilogramm. Es gibt keinen Lagerbestand.
final class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.nameAr,
    required this.category,
    required this.unit,
    required this.unitsPerCarton,
    required this.buyPrice,
    required this.sellPrice,
    required this.vatRate,
    required this.imagePath,
    required this.active,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] as String,
    sku: json['sku'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String?,
    category: json['category'] as String,
    unit: ProductUnit.fromDb(json['unit'] as String),
    unitsPerCarton: json['units_per_carton'] as int?,
    buyPrice: Money(json['buy_price_net_cents'] as int),
    sellPrice: Money(json['sell_price_net_cents'] as int),
    vatRate: VatRate.fromPercent(json['vat_rate'] as int),
    imagePath: json['image_path'] as String?,
    active: json['active'] as bool,
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  /// Spalten, die abgefragt werden.
  static const columns =
      'id,sku,name,name_ar,category,unit,units_per_carton,buy_price_net_cents,'
      'sell_price_net_cents,vat_rate,image_path,active,'
      'updated_at';

  final String id;
  final String sku;
  final String name;

  /// Arabischer Name (freiwillig).
  final String? nameAr;
  final String category;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Money buyPrice;
  final Money sellPrice;
  final VatRate vatRate;
  final String? imagePath;
  final bool active;

  /// Zeitpunkt der letzten Änderung; dient der Konflikterkennung.
  final DateTime updatedAt;

  /// Marge pro Einheit (VK − EK).
  Money get margin => sellPrice - buyPrice;

  /// Marge in ganzen Prozent vom Verkaufspreis; `null` bei Preis 0.
  int? get marginPercent => sellPrice.isZero
      ? null
      : roundHalfAwayFromZero(margin.cents * 100, sellPrice.cents);
}

/// Eingaben des Produktformulars.
final class ProductInput {
  const ProductInput({
    required this.name,
    required this.category,
    required this.unit,
    required this.unitsPerCarton,
    required this.buyPrice,
    required this.sellPrice,
    required this.vatRate,
    this.nameAr,
    this.imagePath,
  });

  final String name;
  final String? nameAr;
  final String category;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Money buyPrice;
  final Money sellPrice;
  final VatRate vatRate;

  /// Pfad des Fotos im Bucket `products`; `null` = kein Foto.
  final String? imagePath;

  Map<String, Object?> toJson({required bool creating}) => {
    'name': name.trim(),
    'name_ar': (nameAr?.trim().isEmpty ?? true) ? null : nameAr!.trim(),
    'category': category.trim(),
    'unit': unit.dbValue,
    'units_per_carton': unit.isWeight || unit == ProductUnit.carton
        ? null
        : unitsPerCarton,
    'buy_price_net_cents': buyPrice.cents,
    'sell_price_net_cents': sellPrice.cents,
    'vat_rate': vatRate.percent,
    'image_path': imagePath,
  };
}

/// Filter der Produktliste.
enum ProductFilter { all, inactive }

/// Name eines Produkts in der Sprache der Oberfläche: Arabisch, wenn die App
/// arabisch läuft und ein arabischer Name da ist, sonst der Hauptname.
String localizedProductName({
  required String name,
  required String? nameAr,
  required String languageCode,
}) {
  final arabic = nameAr?.trim() ?? '';
  return languageCode == 'ar' && arabic.isNotEmpty ? arabic : name;
}

/// Ein Produkt im Inhalt eines Kartons: Menge je Karton in der Basiseinheit des
/// enthaltenen Produkts.
final class ProductContent {
  const ProductContent({
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.unit,
    required this.unitsPerCarton,
    required this.quantity,
  });

  factory ProductContent.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    final unit = ProductUnit.fromDb(content['unit'] as String);
    return ProductContent(
      productId: content['id'] as String,
      name: content['name'] as String,
      nameAr: content['name_ar'] as String?,
      unit: unit,
      unitsPerCarton: content['units_per_carton'] as int?,
      quantity: Quantity(json['qty'] as int, unit),
    );
  }

  static const columns =
      'qty,content:products!product_contents_content_product_id_fkey('
      'id,name,name_ar,unit,units_per_carton)';

  final String productId;
  final String name;
  final String? nameAr;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Quantity quantity;

  ProductContent withQuantity(Quantity value) => ProductContent(
    productId: productId,
    name: name,
    nameAr: nameAr,
    unit: unit,
    unitsPerCarton: unitsPerCarton,
    quantity: value,
  );

  String displayName(String languageCode) => localizedProductName(
    name: name,
    nameAr: nameAr,
    languageCode: languageCode,
  );
}
