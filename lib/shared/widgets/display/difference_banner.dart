import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';

/// Kassendifferenz einer Tour: Fehlbetrag (Fehlerfarbe), Überschuss oder
/// „Kasse stimmt“ (Erfolgsfarbe). Der Wert kommt aus der Berechnung bzw. der
/// Datenbank.
class DifferenceBanner extends StatelessWidget {
  const DifferenceBanner({required this.difference, super.key});

  final Money difference;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    // Betrag als Ganzes von links nach rechts lesen (auch in RTL-Text):
    // Isolat-Zeichen LRI (U+2066) und PDI (U+2069).
    final amount =
        '${String.fromCharCode(0x2066)}${MoneyFormatter.formatSigned(difference)}'
        '${String.fromCharCode(0x2069)}';
    final (text, kind) = difference.isZero
        ? (strings.cashBalanced, NoticeKind.success)
        : difference.isNegative
        ? (strings.shortfall(amount), NoticeKind.error)
        : (strings.surplus(amount), NoticeKind.success);
    return Semantics(
      liveRegion: true,
      child: NoticeBanner(message: text, kind: kind),
    );
  }
}
