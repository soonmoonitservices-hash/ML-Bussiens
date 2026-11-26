import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';

/// Artikel-, Tour- und Rechnungsnummern in IBM Plex Mono, 13, grau. Immer
/// von links nach rechts gelesen, auch in der arabischen Oberfläche.
class CodeText extends StatelessWidget {
  const CodeText(this.value, {super.key});

  final String value;

  @override
  Widget build(BuildContext context) =>
      Text(value, style: AppText.code, textDirection: TextDirection.ltr);
}
