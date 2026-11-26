import 'package:warenbestand/core/value_objects/quantity.dart';

/// Filter der Lieferscheinliste.
enum DeliveryFilter { all, signed, open }

/// Ein Lieferschein (Zeile aus `delivery_notes`).
final class DeliveryNote {
  const DeliveryNote({
    required this.id,
    required this.number,
    required this.date,
    required this.recipientName,
    required this.recipientAddress,
    required this.tourId,
    required this.tourNumber,
    required this.note,
    required this.signaturePath,
    required this.signerName,
    required this.signedAt,
    required this.pdfPath,
    required this.updatedAt,
  });

  factory DeliveryNote.fromJson(Map<String, dynamic> json) {
    final tour = json['tours'] as Map<String, dynamic>?;
    return DeliveryNote(
      id: json['id'] as String,
      number: json['number'] as String,
      date: DateTime.parse(json['date'] as String),
      recipientName: json['recipient_name'] as String,
      recipientAddress: json['recipient_address'] as String,
      tourId: json['tour_id'] as String?,
      tourNumber: tour?['number'] as String?,
      note: json['note'] as String?,
      signaturePath: json['signature_path'] as String?,
      signerName: json['signer_name'] as String?,
      signedAt: json['signed_at'] == null
          ? null
          : DateTime.parse(json['signed_at'] as String).toLocal(),
      pdfPath: json['pdf_path'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static const columns =
      'id,number,date,recipient_name,recipient_address,tour_id,note,'
      'signature_path,signer_name,signed_at,pdf_path,updated_at,tours(number)';

  final String id;
  final String number;
  final DateTime date;
  final String recipientName;
  final String recipientAddress;
  final String? tourId;
  final String? tourNumber;
  final String? note;
  final String? signaturePath;
  final String? signerName;
  final DateTime? signedAt;
  final String? pdfPath;
  final DateTime updatedAt;

  bool get isSigned => signedAt != null;
}

/// Eine gespeicherte Position (mit kopiertem Namen und Einheit).
final class DeliveryNoteItem {
  const DeliveryNoteItem({
    required this.productId,
    required this.name,
    required this.unitsPerCarton,
    required this.quantity,
    required this.sortOrder,
  });

  factory DeliveryNoteItem.fromJson(Map<String, dynamic> json) {
    final unit = ProductUnit.fromDb(json['unit'] as String);
    return DeliveryNoteItem(
      productId: json['product_id'] as String,
      name: json['product_name'] as String,
      unitsPerCarton: json['units_per_carton'] as int?,
      quantity: Quantity(json['qty'] as int, unit),
      sortOrder:
          (json['products'] as Map<String, dynamic>?)?['sort_order'] as int?,
    );
  }

  static const columns =
      'product_id,product_name,unit,units_per_carton,qty,products(sort_order)';

  final String productId;
  final String name;
  final int? unitsPerCarton;
  final Quantity quantity;

  /// Platz des Produkts in der eigenen Produkt-Reihenfolge.
  final int? sortOrder;
}

/// Produkt zur Auswahl im Lieferschein.
final class DeliveryProduct {
  const DeliveryProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.unit,
    required this.unitsPerCarton,
    required this.sortOrder,
  });

  factory DeliveryProduct.fromJson(Map<String, dynamic> json) =>
      DeliveryProduct(
        id: json['id'] as String,
        sku: json['sku'] as String,
        name: json['name'] as String,
        unit: ProductUnit.fromDb(json['unit'] as String),
        unitsPerCarton: json['units_per_carton'] as int?,
        sortOrder: json['sort_order'] as int,
      );

  static const columns = 'id,sku,name,unit,units_per_carton,sort_order';

  /// Wie in der Datenbank, damit [DeliveryProduct.fromJson] es wieder lesen
  /// kann (für den gemerkten Formularstand).
  Map<String, Object?> toJson() => {
    'id': id,
    'sku': sku,
    'name': name,
    'unit': unit.dbValue,
    'units_per_carton': unitsPerCarton,
    'sort_order': sortOrder,
  };

  final String id;
  final String sku;
  final String name;
  final ProductUnit unit;
  final int? unitsPerCarton;

  /// Platz in der eigenen Produkt-Reihenfolge.
  final int sortOrder;
}

/// Position im Formular: Produkt und Menge.
final class DeliveryDraftItem {
  const DeliveryDraftItem({required this.product, required this.quantity});

  final DeliveryProduct product;
  final Quantity quantity;

  DeliveryDraftItem withQuantity(Quantity value) =>
      DeliveryDraftItem(product: product, quantity: value);
}

/// Tour zur Auswahl (Positionen werden übernommen).
final class DeliveryTour {
  const DeliveryTour({
    required this.id,
    required this.number,
    required this.driverName,
    required this.plannedAt,
  });

  factory DeliveryTour.fromJson(Map<String, dynamic> json) => DeliveryTour(
    id: json['id'] as String,
    number: json['number'] as String?,
    driverName: json['driver_name'] as String,
    plannedAt: DateTime.parse(json['planned_at'] as String).toLocal(),
  );

  final String id;
  final String? number;
  final String driverName;
  final DateTime plannedAt;
}

/// Eingaben des Lieferschein-Formulars.
final class DeliveryNoteInput {
  const DeliveryNoteInput({
    required this.recipientName,
    required this.recipientAddress,
    required this.date,
    required this.tourId,
    required this.note,
    required this.items,
  });

  final String recipientName;
  final String recipientAddress;
  final DateTime date;
  final String? tourId;
  final String? note;
  final List<DeliveryDraftItem> items;
}
