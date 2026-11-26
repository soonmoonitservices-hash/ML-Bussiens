import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Status einer Rechnung (wie `invoice_status` in der Datenbank).
enum InvoiceStatus {
  draft('draft'),
  open('open'),
  paid('paid'),
  overdue('overdue'),
  cancelled('cancelled');

  const InvoiceStatus(this.dbValue);

  final String dbValue;

  static InvoiceStatus fromDb(String value) =>
      InvoiceStatus.values.firstWhere((status) => status.dbValue == value);
}

/// Filter der Rechnungsliste.
enum InvoiceFilter { all, open, paid, overdue, draft }

/// Eine Rechnung (Zeile aus `invoices`). Summen berechnet die Datenbank.
final class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.date,
    required this.serviceDate,
    required this.dueDate,
    required this.recipientName,
    required this.recipientAddress,
    required this.recipientVatId,
    required this.note,
    required this.net,
    required this.vat7,
    required this.vat19,
    required this.gross,
    required this.status,
    required this.paidAt,
    required this.cancelsInvoiceId,
    required this.cancelledByInvoiceId,
    required this.tourId,
    required this.deliveryNoteId,
    required this.deliveryNoteNumber,
    required this.pdfPath,
    required this.isSmallBusiness,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final note = json['delivery_notes'] as Map<String, dynamic>?;
    DateTime? date(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);
    return Invoice(
      id: json['id'] as String,
      number: json['number'] as String?,
      date: DateTime.parse(json['date'] as String),
      serviceDate: DateTime.parse(json['service_date'] as String),
      dueDate: date('due_date'),
      recipientName: json['recipient_name'] as String,
      recipientAddress: json['recipient_address'] as String,
      recipientVatId: json['recipient_vat_id'] as String?,
      note: json['note'] as String?,
      net: Money(json['net_cents'] as int),
      vat7: Money(json['vat7_cents'] as int),
      vat19: Money(json['vat19_cents'] as int),
      gross: Money(json['gross_cents'] as int),
      status: InvoiceStatus.fromDb(json['status'] as String),
      paidAt: date('paid_at'),
      cancelsInvoiceId: json['cancels_invoice_id'] as String?,
      cancelledByInvoiceId: json['cancelled_by_invoice_id'] as String?,
      tourId: json['tour_id'] as String?,
      deliveryNoteId: json['delivery_note_id'] as String?,
      deliveryNoteNumber: note?['number'] as String?,
      pdfPath: json['pdf_path'] as String?,
      isSmallBusiness: json['is_small_business'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static const columns =
      'id,number,date,service_date,due_date,recipient_name,recipient_address,'
      'recipient_vat_id,note,net_cents,vat7_cents,vat19_cents,gross_cents,'
      'status,paid_at,cancels_invoice_id,cancelled_by_invoice_id,tour_id,'
      'delivery_note_id,pdf_path,is_small_business,updated_at,'
      'delivery_notes(number)';

  final String id;
  final String? number;
  final DateTime date;
  final DateTime serviceDate;
  final DateTime? dueDate;
  final String recipientName;
  final String recipientAddress;
  final String? recipientVatId;
  final String? note;
  final Money net;
  final Money vat7;
  final Money vat19;
  final Money gross;
  final InvoiceStatus status;
  final DateTime? paidAt;
  final String? cancelsInvoiceId;
  final String? cancelledByInvoiceId;
  final String? tourId;
  final String? deliveryNoteId;
  final String? deliveryNoteNumber;
  final String? pdfPath;
  final bool isSmallBusiness;
  final DateTime updatedAt;

  bool get isDraft => status == InvoiceStatus.draft;
  bool get isCancellation => cancelsInvoiceId != null;
}

/// Eine gespeicherte Position (Name, Einheit, USt und Preis kopiert).
final class InvoiceItem {
  const InvoiceItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.priceNet,
    required this.vatRate,
    required this.lineNet,
    required this.sortOrder,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    final unit = ProductUnit.fromDb(json['unit'] as String);
    return InvoiceItem(
      productId: json['product_id'] as String?,
      name: json['product_name'] as String,
      quantity: Quantity(json['qty'] as int, unit),
      priceNet: Money(json['price_net_cents'] as int),
      vatRate: VatRate.fromPercent(json['vat_rate'] as int),
      lineNet: Money(json['line_net_cents'] as int),
      sortOrder:
          (json['products'] as Map<String, dynamic>?)?['sort_order'] as int?,
    );
  }

  static const columns =
      'product_id,product_name,unit,qty,price_net_cents,vat_rate,'
      'line_net_cents,products(sort_order)';

  final String? productId;
  final String name;
  final Quantity quantity;
  final Money priceNet;
  final VatRate vatRate;

  /// Gesamt netto der Position (aus der Datenbank).
  final Money lineNet;

  /// Platz des Produkts in der eigenen Produkt-Reihenfolge (`null` bei freien
  /// Positionen).
  final int? sortOrder;
}

/// Eine Position im Formular: Produkt oder freie Position.
final class InvoiceDraftLine {
  const InvoiceDraftLine({
    required this.name,
    required this.quantity,
    required this.priceNet,
    required this.vatRate,
    this.productId,
    this.unitsPerCarton,
    this.sortOrder,
  });

  /// Frei erfasste Position (ohne Produkt).
  factory InvoiceDraftLine.free({
    required String name,
    required ProductUnit unit,
    required VatRate vatRate,
  }) => InvoiceDraftLine(
    name: name,
    quantity: Quantity.zero(unit),
    priceNet: Money.zero,
    vatRate: vatRate,
  );

  final String? productId;
  final String name;
  final int? unitsPerCarton;
  final Quantity quantity;
  final Money priceNet;
  final VatRate vatRate;

  /// Platz des Produkts in der eigenen Produkt-Reihenfolge (`null` bei freien
  /// Positionen).
  final int? sortOrder;

  bool get isFree => productId == null;

  InvoiceDraftLine copyWith({
    String? name,
    Quantity? quantity,
    Money? priceNet,
    VatRate? vatRate,
  }) => InvoiceDraftLine(
    productId: productId,
    name: name ?? this.name,
    unitsPerCarton: unitsPerCarton,
    sortOrder: sortOrder,
    quantity: quantity ?? this.quantity,
    priceNet: priceNet ?? this.priceNet,
    vatRate: vatRate ?? this.vatRate,
  );
}

/// Produkt zur Auswahl in der Rechnung.
final class InvoiceProduct {
  const InvoiceProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.nameAr,
    required this.unit,
    required this.unitsPerCarton,
    required this.sellPrice,
    required this.vatRate,
    required this.sortOrder,
  });

  factory InvoiceProduct.fromJson(Map<String, dynamic> json) => InvoiceProduct(
    id: json['id'] as String,
    sku: json['sku'] as String,
    name: json['name'] as String,
    nameAr: json['name_ar'] as String?,
    unit: ProductUnit.fromDb(json['unit'] as String),
    unitsPerCarton: json['units_per_carton'] as int?,
    sellPrice: Money(json['sell_price_net_cents'] as int),
    vatRate: VatRate.fromPercent(json['vat_rate'] as int),
    sortOrder: json['sort_order'] as int,
  );

  static const columns =
      'id,sku,name,name_ar,unit,units_per_carton,sell_price_net_cents,vat_rate,'
      'sort_order';

  final String id;
  final String sku;
  final String name;
  final String? nameAr;
  final ProductUnit unit;
  final int? unitsPerCarton;
  final Money sellPrice;
  final VatRate vatRate;

  /// Platz in der eigenen Produkt-Reihenfolge.
  final int sortOrder;

  InvoiceDraftLine toLine() => InvoiceDraftLine(
    productId: id,
    name: name,
    unitsPerCarton: unitsPerCarton,
    sortOrder: sortOrder,
    quantity: Quantity.zero(unit),
    priceNet: sellPrice,
    vatRate: vatRate,
  );

  /// Name in der Sprache der Oberfläche (Arabisch, wenn vorhanden).
  String displayName(String languageCode) =>
      languageCode == 'ar' && (nameAr?.trim().isNotEmpty ?? false)
      ? nameAr!.trim()
      : name;
}

/// Eingaben des Rechnungsformulars.
final class InvoiceInput {
  const InvoiceInput({
    required this.recipientName,
    required this.recipientAddress,
    required this.recipientVatId,
    required this.date,
    required this.serviceDate,
    required this.dueDate,
    required this.note,
    required this.lines,
  });

  final String recipientName;
  final String recipientAddress;
  final String? recipientVatId;
  final DateTime date;
  final DateTime serviceDate;
  final DateTime dueDate;
  final String? note;
  final List<InvoiceDraftLine> lines;
}

/// Kennzahlen über der Rechnungsliste (Sicht `v_open_invoices`).
final class OpenInvoicesSummary {
  const OpenInvoicesSummary({
    required this.openGross,
    required this.openCount,
    required this.overdueCount,
  });

  static const empty = OpenInvoicesSummary(
    openGross: Money.zero,
    openCount: 0,
    overdueCount: 0,
  );

  final Money openGross;
  final int openCount;
  final int overdueCount;
}
