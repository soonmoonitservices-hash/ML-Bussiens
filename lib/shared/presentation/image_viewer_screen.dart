import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';

/// Was der Bildbetrachter zeigt: eine Funktion, die die Bild-Bytes liefert.
final class ImageViewerArgs {
  const ImageViewerArgs({required this.title, required this.load});

  final String title;
  final Future<Result<Uint8List>> Function() load;
}

/// Vollbild mit schwarzem Hintergrund, Zoomen und Verschieben mit den Fingern.
class ImageViewerScreen extends StatefulWidget {
  const ImageViewerScreen({required this.args, super.key});

  final ImageViewerArgs args;

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  Uint8List? _bytes;
  AppError? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final result = await widget.args.load();
    if (!mounted) return;
    setState(() {
      switch (result) {
        case Success(:final value):
          _bytes = value;
        case Failure(:final error):
          _error = error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final bytes = _bytes;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: bytes != null
                  ? InteractiveViewer(
                      maxScale: 6,
                      child: Center(child: Image.memory(bytes)),
                    )
                  : Center(
                      child: _error == null
                          ? const CircularProgressIndicator(
                              color: AppColors.paper,
                            )
                          : Text(
                              _error!.localized(strings),
                              style: AppText.body.copyWith(
                                color: AppColors.paper,
                              ),
                            ),
                    ),
            ),
            PositionedDirectional(
              top: AppSpacing.xs,
              start: AppSpacing.xs,
              child: IconButton(
                tooltip: strings.back,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(AppIcons.back(context), color: AppColors.paper),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
