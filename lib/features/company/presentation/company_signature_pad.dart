import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:signature/signature.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';

/// Zeichenfeld für die Unterschrift der Firma. Gibt das PNG zurück oder
/// `null`, wenn abgebrochen wurde.
Future<Uint8List?> showCompanySignaturePad(BuildContext context) =>
    showModalBottomSheet<Uint8List>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _SignaturePad(),
    );

class _SignaturePad extends StatefulWidget {
  const _SignaturePad();

  @override
  State<_SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<_SignaturePad> {
  final _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.ink,
  );
  bool _missing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    final png = await _controller.toPngBytes();
    if (png == null || !mounted) return;
    Navigator.of(context).pop(png);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(strings.companySignature, style: AppText.label),
            const SizedBox(height: AppSpacing.sm),
            // Die Fläche verbraucht Wischgesten selbst.
            GestureDetector(
              onVerticalDragUpdate: (_) {},
              onHorizontalDragUpdate: (_) {},
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  border: Border.all(
                    color: _missing ? AppColors.error : AppColors.inkMuted,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Signature(
                  controller: _controller,
                  height: 220,
                  backgroundColor: AppColors.paper,
                ),
              ),
            ),
            if (_missing)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.xs),
                child: Text(strings.signatureMissing, style: AppText.label),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: strings.signatureClear,
                    onPressed: () => setState(() {
                      _controller.clear();
                      _missing = false;
                    }),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PrimaryButton(label: strings.save, onPressed: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
