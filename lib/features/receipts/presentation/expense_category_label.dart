import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Anzeigetext einer gespeicherten (deutschen) Kategorie in der Sprache der
/// App; unbekannte Kategorien erscheinen unverändert.
String expenseCategoryText(AppLocalizations strings, String stored) =>
    switch (stored) {
      ExpenseCategories.vehicle => strings.categoryVehicle,
      ExpenseCategories.rent => strings.categoryRent,
      ExpenseCategories.maintenance => strings.categoryMaintenance,
      ExpenseCategories.meals => strings.categoryMeals,
      ExpenseCategories.other => strings.categoryOther,
      _ => stored,
    };
