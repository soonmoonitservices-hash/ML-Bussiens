import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';

/// Was die PDF-Vorschau zeigt: Titel, Dateiname und eine Funktion, die die
/// PDF-Bytes liefert (gespeichertes oder frisch erzeugtes Dokument).
final class PdfPreviewArgs {
  const PdfPreviewArgs({
    required this.title,
    required this.fileName,
    required this.load,
  });

  final String title;
  final String fileName;
  final Future<Result<Uint8List>> Function() load;
}

/// PDF-Vorschau für alle Dokumente: Seiten scrollen mit, darunter Teilen und
/// Drucken. Das Teilen-Menü der Plattform bietet auch „In Dateien sichern“.
class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({required this.args, super.key});

  final PdfPreviewArgs args;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  Uint8List? _bytes;
  final _pages = <Uint8List>[];
  AppError? _error;
  bool _loading = true;
  bool _previewFailed = false;

  /// Technische Fehlermeldung, damit die Ursache auf dem Gerät sichtbar ist.
  String? _detail;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _pages.clear();
    });
    Result<Uint8List> result;
    try {
      result = await widget.args.load();
    } on Object catch (e) {
      _detail = '$e';
      result = const Failure(UnexpectedError());
    }
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        _bytes = value;
        try {
          await for (final page in Printing.raster(value, dpi: 110)) {
            final png = await page.toPng();
            if (!mounted) return;
            setState(() => _pages.add(png));
          }
        } on Object catch (e) {
          _detail = '$e';
          _previewFailed = true; // Teilen und Drucken gehen trotzdem.
        }
        if (mounted) setState(() => _loading = false);
      case Failure(:final error):
        setState(() {
          if (error is UnexpectedError) _detail = error.message;
          _error = error;
          _loading = false;
        });
    }
  }

  /// Klick, solange es noch kein PDF gibt: sagen warum, statt nichts zu tun.
  void _notReady() {
    final strings = AppLocalizations.of(context);
    showErrorSnack(
      context,
      _loading ? strings.pdfPleaseWait : strings.pdfNothingToShow,
    );
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: widget.args.fileName,
          ),
        ],
        fileNameOverrides: [widget.args.fileName],
      ),
    );
  }

  Future<void> _print() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await Printing.layoutPdf(
      name: widget.args.fileName,
      onLayout: (_) async => bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return AppScreen(
      title: widget.args.title,
      children: [
        if (_error != null) ...[
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
          TextButton(onPressed: _load, child: Text(strings.retry)),
        ],
        for (final page in _pages)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
              ),
              child: Image.memory(page, fit: BoxFit.fitWidth),
            ),
          ),
        if (!_loading && (_previewFailed || _pages.isEmpty) && _error == null)
          NoticeBanner(message: strings.pdfNoPreview, kind: NoticeKind.warning),
        if (_detail != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: SelectableText(_detail!, style: AppText.label),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: strings.share,
          icon: AppIcons.share,
          onPressed: _bytes == null ? _notReady : _share,
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.print,
          icon: AppIcons.pdf,
          onPressed: _bytes == null ? _notReady : _print,
        ),
      ],
    );
  }
}
