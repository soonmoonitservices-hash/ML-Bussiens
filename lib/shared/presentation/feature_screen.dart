import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Platzhalter für Bereiche, die noch nicht gebaut sind. Der Titel kommt aus
/// den ARB-Dateien und ist damit in beiden Sprachen vorhanden.
class FeatureScreen extends StatelessWidget {
  const FeatureScreen({required this.title, super.key});

  final String Function(AppLocalizations strings) title;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: title(strings),
      children: [EmptyState(message: strings.featureUnavailable)],
    );
  }
}
