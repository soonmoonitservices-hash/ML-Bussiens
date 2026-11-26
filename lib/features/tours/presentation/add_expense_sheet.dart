import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/tours/domain/tour.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/inputs/choice_chips.dart';
import 'package:warenbestand/shared/widgets/inputs/money_field.dart';

/// Art einer Tour-Ausgabe. Die Kategorie wird deutsch gespeichert, damit die
/// Monatsübersicht der Belege einheitlich bleibt.
enum _ExpenseKind {
  diesel('Diesel', 'Fahrzeug & Kraftstoff'),
  meal('Essen', 'Verpflegung'),
  parking('Parken', 'Fahrzeug & Kraftstoff'),
  other('Sonstiges', 'Sonstiges');

  const _ExpenseKind(this.title, this.category);

  final String title;
  final String category;
}

/// Ausgabe schnell hinzufügen: Art, Betrag, USt. Liefert die Eingabe oder
/// `null` bei Abbruch.
Future<TourExpenseInput?> showAddExpenseSheet(BuildContext context) =>
    showModalBottomSheet<TourExpenseInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.paper,
      builder: (context) => const _AddExpenseSheet(),
    );

class _AddExpenseSheet extends StatefulWidget {
  const _AddExpenseSheet();

  @override
  State<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  _ExpenseKind _kind = _ExpenseKind.diesel;
  final VatRate _vat = VatRate.zero;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      TourExpenseInput(
        title: _kind.title,
        category: _kind.category,
        gross: MoneyField.read(_amount)!,
        vatRate: _vat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final kinds = [
      (value: _ExpenseKind.diesel, label: strings.expenseDiesel),
      (value: _ExpenseKind.meal, label: strings.expenseMeal),
      (value: _ExpenseKind.parking, label: strings.expenseParking),
      (value: _ExpenseKind.other, label: strings.expenseOther),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(strings.addExpense, style: AppText.section),
              const SizedBox(height: AppSpacing.md),
              Text(strings.expenseType, style: AppText.label),
              const SizedBox(height: AppSpacing.xs),
              ChoiceChips<_ExpenseKind>(
                options: kinds,
                selected: _kind,
                onSelected: (value) => setState(() => _kind = value),
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyField(controller: _amount, label: strings.amountGross),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: strings.addExpense, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
