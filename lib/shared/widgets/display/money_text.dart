import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';

/// Betrag mit tabellarischen Ziffern, am Zeilenende ausgerichtet.
/// [large] ist die Größe 30 für Kennzahlen.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    this.large = false,
    this.signed = false,
    this.color,
    super.key,
  });

  final Money money;
  final bool large;

  /// Mit Vorzeichen (`+2,00 €`), z. B. für Differenzen.
  final bool signed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = (large ? AppText.amountLarge : AppText.amount).copyWith(
      color: color,
    );
    return Text(
      signed
          ? MoneyFormatter.formatSigned(money)
          : MoneyFormatter.format(money),
      style: style,
      textAlign: TextAlign.end,
      textDirection: TextDirection.ltr,
    );
  }
}
