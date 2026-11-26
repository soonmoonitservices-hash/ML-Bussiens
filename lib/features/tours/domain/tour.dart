import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Status einer Tour (wie `tour_status` in der Datenbank).
enum TourStatus {
  draft('draft'),
  active('active'),
  closed('closed');

  const TourStatus(this.dbValue);

  final String dbValue;

  static TourStatus fromDb(String value) =>
      TourStatus.values.firstWhere((status) => status.dbValue == value);
}

Money _money(Object? value) => Money((value as num?)?.toInt() ?? 0);

Money? _moneyOrNull(Object? value) =>
    value == null ? null : Money((value as num).toInt());

/// Eine Tour mit Kennzahlen (Sicht `v_tour_overview`). Bei abgeschlossenen
/// Touren sind die `frozen*`-Werte gesetzt, sonst nur die Ladungswerte.
final class Tour {
  const Tour({
    required this.id,
    required this.number,
    required this.driverId,
    required this.driverName,
    required this.name,
    required this.plannedAt,
    required this.status,
    required this.startedAt,
    required this.closedAt,
    required this.itemCount,
    required this.loadedValueBuy,
    required this.loadedValueSell,
    required this.liveExpensesGross,
    required this.revenueNet,
    required this.expensesGross,
    required this.expectedCash,
    required this.cashReceived,
    required this.difference,
    required this.differenceReason,
    required this.cost,
    required this.profit,
    required this.updatedAt,
  });

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
    id: json['id'] as String,
    number: json['number'] as String?,
    driverId: json['driver_id'] as String,
    driverName: json['driver_name'] as String,
    name: json['name'] as String?,
    plannedAt: DateTime.parse(json['planned_at'] as String).toLocal(),
    status: TourStatus.fromDb(json['status'] as String),
    startedAt: json['started_at'] == null
        ? null
        : DateTime.parse(json['started_at'] as String).toLocal(),
    closedAt: json['closed_at'] == null
        ? null
        : DateTime.parse(json['closed_at'] as String).toLocal(),
    itemCount: (json['item_count'] as num).toInt(),
    loadedValueBuy: _money(json['loaded_value_buy_cents']),
    loadedValueSell: _money(json['loaded_value_sell_cents']),
    liveExpensesGross: _money(json['live_expenses_gross_cents']),
    revenueNet: _moneyOrNull(json['revenue_net_cents']),
    expensesGross: _moneyOrNull(json['expenses_gross_cents']),
    expectedCash: _moneyOrNull(json['expected_cash_cents']),
    cashReceived: _moneyOrNull(json['cash_received_cents']),
    difference: _moneyOrNull(json['difference_cents']),
    differenceReason: json['difference_reason'] as String?,
    cost: _moneyOrNull(json['cost_cents']),
    profit: _moneyOrNull(json['profit_cents']),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  static const columns =
      'id,number,driver_id,driver_name,name,planned_at,status,started_at,'
      'closed_at,item_count,loaded_value_buy_cents,loaded_value_sell_cents,'
      'live_expenses_gross_cents,revenue_net_cents,expenses_gross_cents,'
      'expected_cash_cents,cash_received_cents,difference_cents,'
      'difference_reason,cost_cents,profit_cents,updated_at';

  final String id;
  final String? number;
  final String driverId;
  final String driverName;
  final String? name;
  final DateTime plannedAt;
  final TourStatus status;
  final DateTime? startedAt;
  final DateTime? closedAt;
  final int itemCount;

  /// Warenwert der Ladung zum Einkaufspreis (aus der Datenbank).
  final Money loadedValueBuy;

  /// Warenwert der Ladung zum Verkaufspreis (aus der Datenbank).
  final Money loadedValueSell;
  final Money liveExpensesGross;

  // Eingefroren beim Abschluss; sonst `null`.
  final Money? revenueNet;
  final Money? expensesGross;
  final Money? expectedCash;
  final Money? cashReceived;
  final Money? difference;
  final String? differenceReason;
  final Money? cost;
  final Money? profit;
  final DateTime updatedAt;

  /// Erwarteter Gewinn, wenn die gesamte Ladung verkauft wird.
  Money get expectedProfit => loadedValueSell - loadedValueBuy;

  /// Titel: Tourname, sonst Fahrer.
  String get title =>
      (name != null && name!.trim().isNotEmpty) ? name!.trim() : driverName;
}

/// Produkt, das geladen werden kann (Auszug aus `products`).
final class TourProduct {
  const TourProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.nameAr,
    required this.unit,
    required this.unitsPerCarton,
    required this.buyPrice,
    required this.sellPrice,
    required this.sortOrder,
  });

  factory TourProduct.fromJson(Map<String, dynamic> json) => TourProduct(
    id: json['id'] as String,
    sku: json['sku'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String?,
    unit: ProductUnit.fromDb(json['unit'] as String),
    unitsPerCarton: json['units_per_carton'] as int?,
    buyPrice: Money(json['buy_price_net_cents'] as int),
    sellPrice: Money(json['sell_price_net_cents'] as int),
    sortOrder: json['sort_order'] as int,
  );

  static const columns =
      'id,sku,name,name_ar,unit,units_per_carton,buy_price_net_cents,'
      'sell_price_net_cents,sort_order';

  /// Wie in der Datenbank, damit [TourProduct.fromJson] es wieder lesen kann
  /// (für den gemerkten Formularstand).
  Map<String, Object?> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    'name_ar': nameAr,
    'unit': unit.dbValue,
    'units_per_carton': unitsPerCarton,
    'buy_price_net_cents': buyPrice.cents,
    'sell_price_net_cents': sellPrice.cents,
    'sort_order': sortOrder,
  };

  final String id;
  final String sku;
  final String name;
  final String? nameAr;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Money buyPrice;
  final Money sellPrice;

  /// Platz in der eigenen Produkt-Reihenfolge.
  final int sortOrder;

  /// Name in der Sprache der Oberfläche (Arabisch, wenn vorhanden).
  String displayName(String languageCode) =>
      languageCode == 'ar' && (nameAr?.trim().isNotEmpty ?? false)
      ? nameAr!.trim()
      : name;
}

/// Eine Position der Ladung (Produkt und Menge).
final class LoadItem {
  const LoadItem({required this.product, required this.quantity});

  final TourProduct product;
  final Quantity quantity;

  LoadItem withQuantity(Quantity value) =>
      LoadItem(product: product, quantity: value);
}

/// Eine gespeicherte Position einer Tour (mit kopierten Preisen).
final class TourItem {
  const TourItem({
    required this.productId,
    required this.vatRate,
    required this.name,
    required this.unit,
    required this.unitsPerCarton,
    required this.buyPrice,
    required this.sellPrice,
    required this.loaded,
    required this.returned,
    this.gift,
    this.removedRevenue = Money.zero,
  });

  factory TourItem.fromJson(Map<String, dynamic> json) {
    final unit = ProductUnit.fromDb(json['unit'] as String);
    return TourItem(
      productId: json['product_id'] as String,
      vatRate: VatRate.fromPercent(json['vat_rate'] as int),
      name: json['product_name'] as String,
      unit: unit,
      unitsPerCarton: json['units_per_carton'] as int?,
      buyPrice: Money(json['buy_price_cents'] as int),
      sellPrice: Money(json['sell_price_cents'] as int),
      loaded: Quantity(json['loaded_qty'] as int, unit),
      returned: Quantity(json['returned_qty'] as int, unit),
      gift: Quantity((json['gift_qty'] as int?) ?? 0, unit),
      removedRevenue: Money((json['removed_revenue_cents'] as int?) ?? 0),
    );
  }

  static const columns =
      'product_id,product_name,unit,units_per_carton,buy_price_cents,'
      'sell_price_cents,vat_rate,loaded_qty,returned_qty,gift_qty,'
      'removed_revenue_cents';

  final VatRate vatRate;
  final String productId;
  final String name;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Money buyPrice;
  final Money sellPrice;
  final Quantity loaded;
  final Quantity returned;

  /// Verschenkte Menge (kein Umsatz).
  final Quantity? gift;

  /// Verkaufswert der aus einem Karton entfernten Produkte.
  final Money removedRevenue;

  /// Verschenkte Menge, 0 wenn nichts verschenkt wurde.
  Quantity get giftQty => gift ?? Quantity.zero(unit);

  /// Bezahlte Menge = geladen − zurück − geschenkt.
  Quantity get sold => loaded - returned - giftQty;
}

/// Ein Fahrer zur Auswahl.
final class TourDriver {
  const TourDriver({required this.id, required this.name, this.vehicle});

  factory TourDriver.fromJson(Map<String, dynamic> json) => TourDriver(
    id: json['id'] as String,
    name: json['name'] as String,
    vehicle: json['vehicle'] as String?,
  );

  final String id;
  final String name;
  final String? vehicle;
}

/// Eine Ausgabe, die zu einer Tour gehört (Zeile aus `expenses`).
final class TourExpense {
  const TourExpense({
    required this.id,
    required this.title,
    required this.gross,
    required this.vatRate,
  });

  factory TourExpense.fromJson(Map<String, dynamic> json) => TourExpense(
    id: json['id'] as String,
    title: json['title'] as String,
    gross: Money(json['gross_cents'] as int),
    vatRate: VatRate.fromPercent(json['vat_rate'] as int),
  );

  static const columns = 'id,title,gross_cents,vat_rate';

  final String id;
  final String title;
  final Money gross;
  final VatRate vatRate;
}

/// Eingabe einer neuen Tour-Ausgabe.
final class TourExpenseInput {
  const TourExpenseInput({
    required this.title,
    required this.category,
    required this.gross,
    required this.vatRate,
  });

  final String title;
  final String category;
  final Money gross;
  final VatRate vatRate;
}

/// Ein Produkt im Inhalt eines Kartons beim Tour-Abschluss: Menge je Karton und
/// die Preise, mit denen entfernte Produkte bewertet werden.
final class TourContent {
  const TourContent({
    required this.cartonId,
    required this.productId,
    required this.name,
    required this.nameAr,
    required this.unit,
    required this.unitsPerCarton,
    required this.perCarton,
    required this.sellPrice,
    required this.buyPrice,
  });

  factory TourContent.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>;
    final unit = ProductUnit.fromDb(content['unit'] as String);
    return TourContent(
      cartonId: json['product_id'] as String,
      productId: content['id'] as String,
      name: content['name'] as String,
      nameAr: content['name_ar'] as String?,
      unit: unit,
      unitsPerCarton: content['units_per_carton'] as int?,
      perCarton: json['qty'] as int,
      sellPrice: Money(content['sell_price_net_cents'] as int),
      buyPrice: Money(content['buy_price_net_cents'] as int),
    );
  }

  static const columns =
      'product_id,qty,content:products!product_contents_content_product_id_fkey('
      'id,name,name_ar,unit,units_per_carton,sell_price_net_cents,'
      'buy_price_net_cents)';

  final String cartonId;
  final String productId;
  final String name;
  final String? nameAr;
  final ProductUnit unit;
  final int? unitsPerCarton;

  /// Menge je Karton in der Basiseinheit des enthaltenen Produkts.
  final int perCarton;
  final Money sellPrice;
  final Money buyPrice;

  String displayName(String languageCode) =>
      languageCode == 'ar' && (nameAr?.trim().isNotEmpty ?? false)
      ? nameAr!.trim()
      : name;
}

/// Aus einem Karton entfernte Menge eines enthaltenen Produkts (Basiseinheit).
final class CartonRemoval {
  const CartonRemoval({required this.returned, required this.gift});

  final Quantity returned;
  final Quantity gift;

  bool get isEmpty => returned.base == 0 && gift.base == 0;
}

/// Ein aus einem Karton entferntes Produkt einer abgeschlossenen Tour.
final class TourRemovalRow {
  const TourRemovalRow({
    required this.cartonProductId,
    required this.contentName,
    required this.unit,
    required this.returned,
    required this.gift,
    required this.sellPrice,
  });

  factory TourRemovalRow.fromJson(Map<String, dynamic> json) {
    final unit = ProductUnit.fromDb(json['unit'] as String);
    final item = json['tour_items'] as Map<String, dynamic>;
    return TourRemovalRow(
      cartonProductId: item['product_id'] as String,
      contentName: json['content_name'] as String,
      unit: unit,
      returned: Quantity(json['returned_qty'] as int, unit),
      gift: Quantity(json['gift_qty'] as int, unit),
      sellPrice: Money(json['sell_price_cents'] as int),
    );
  }

  static const columns =
      'content_name,unit,returned_qty,gift_qty,sell_price_cents,'
      'tour_items!inner(product_id,tour_id)';

  final String cartonProductId;
  final String contentName;
  final ProductUnit unit;
  final Quantity returned;
  final Quantity gift;
  final Money sellPrice;
}
