import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';

/// Filter der Ausgabenliste: alle, Tourkosten (mit Tour), Sonstige (ohne Tour).
enum ExpenseFilter { all, tour, other }

/// Kategorien. Gespeichert wird der deutsche Wert, damit Monatsübersicht und
/// PDF einheitlich bleiben; angezeigt wird er in der Sprache der App.
abstract final class ExpenseCategories {
  static const vehicle = 'Fahrzeug & Kraftstoff';
  static const rent = 'Miete';
  static const maintenance = 'Wartung';
  static const meals = 'Verpflegung';
  static const other = 'Sonstiges';

  static const List<String> all = [vehicle, rent, maintenance, meals, other];
}

/// Eine Ausgabe oder ein Beleg (Zeile aus `expenses`).
final class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.title,
    required this.category,
    required this.gross,
    required this.vatRate,
    required this.net,
    required this.vat,
    required this.imagePath,
    required this.tourId,
    required this.tourNumber,
    required this.note,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final tour = json['tours'] as Map<String, dynamic>?;
    return Expense(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      category: json['category'] as String,
      gross: Money(json['gross_cents'] as int),
      vatRate: VatRate.fromPercent(json['vat_rate'] as int),
      net: Money(json['net_cents'] as int),
      vat: Money(json['vat_cents'] as int),
      imagePath: json['image_path'] as String?,
      tourId: json['tour_id'] as String?,
      tourNumber: tour?['number'] as String?,
      note: json['note'] as String?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static const columns =
      'id,date,title,category,gross_cents,vat_rate,net_cents,vat_cents,'
      'image_path,tour_id,note,updated_at,tours(number)';

  final String id;
  final DateTime date;
  final String title;
  final String category;
  final Money gross;
  final VatRate vatRate;
  final Money net;
  final Money vat;
  final String? imagePath;
  final String? tourId;
  final String? tourNumber;
  final String? note;
  final DateTime updatedAt;

  bool get hasReceipt => imagePath != null && imagePath!.isNotEmpty;
}

/// Eingaben des Formulars.
final class ExpenseInput {
  const ExpenseInput({
    required this.date,
    required this.title,
    required this.category,
    required this.gross,
    required this.vatRate,
    required this.tourId,
    required this.note,
    required this.imagePath,
  });

  final DateTime date;
  final String title;
  final String category;
  final Money gross;
  final VatRate vatRate;
  final String? tourId;
  final String? note;
  final String? imagePath;
}

/// Summen eines Monats (aus der Sicht `v_expenses_by_month`).
final class MonthSummary {
  const MonthSummary({
    required this.count,
    required this.gross,
    required this.net,
    required this.vat,
  });

  static const empty = MonthSummary(
    count: 0,
    gross: Money.zero,
    net: Money.zero,
    vat: Money.zero,
  );

  final int count;
  final Money gross;
  final Money net;
  final Money vat;
}

/// Summe einer Kategorie im Monat.
final class CategorySum {
  const CategorySum({required this.category, required this.gross});

  final String category;
  final Money gross;
}

/// Tour zur Auswahl.
final class ExpenseTour {
  const ExpenseTour({
    required this.id,
    required this.number,
    required this.driverName,
  });

  factory ExpenseTour.fromJson(Map<String, dynamic> json) => ExpenseTour(
    id: json['id'] as String,
    number: json['number'] as String?,
    driverName: json['driver_name'] as String,
  );

  final String id;
  final String? number;
  final String driverName;
}
