import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Eingabefeld für Euro-Beträge (`12,50`). Gelesen wird mit [Money.tryParse];
/// es wird nie mit Kommazahlen gerechnet.
class MoneyField extends StatelessWidget {
  const MoneyField({
    required this.controller,
    required this.label,
    this.required = true,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final ValueChanged<Money?>? onChanged;

  /// Betrag aus dem Text; `null`, wenn leer oder ungültig.
  static Money? read(TextEditingController controller) =>
      Money.tryParse(controller.text);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      style: AppText.amount,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: '€'),
      onChanged: (_) => onChanged?.call(read(controller)),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return required ? strings.requiredField : null;
        final money = Money.tryParse(text);
        return money == null || money.isNegative ? strings.invalidAmount : null;
      },
    );
  }
}
