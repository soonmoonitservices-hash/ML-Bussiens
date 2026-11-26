import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signature/signature.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Empfänger unterschreibt mit dem Finger. Danach ist der Lieferschein
/// gesperrt und das PDF mit Unterschrift wird abgelegt.
class DeliveryNoteSignScreen extends ConsumerStatefulWidget {
  const DeliveryNoteSignScreen({required this.noteId, super.key});

  final String noteId;

  @override
  ConsumerState<DeliveryNoteSignScreen> createState() =>
      _DeliveryNoteSignScreenState();
}

class _DeliveryNoteSignScreenState
    extends ConsumerState<DeliveryNoteSignScreen> {
  final _signature = SignatureController(
    penStrokeWidth: 3,
    penColor: AppColors.ink,
  );
  final _name = TextEditingController();
  DeliveryNote? _note;
  List<DeliveryNoteItem> _items = const [];
  AppError? _error;
  String? _nameError;
  String? _signatureError;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _signature.onDrawEnd = () => setState(() => _signatureError = null);
    unawaited(_load());
  }

  @override
  void dispose() {
    _signature.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final note = await repository.getById(widget.noteId);
    final items = await repository.items(widget.noteId);
    if (!mounted) return;
    switch ((note, items)) {
      case (Success(value: final note), Success(value: final items)):
        setState(() {
          _note = note;
          _items = items;
          _loading = false;
        });
      case (Failure(:final error), _) || (_, Failure(:final error)):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _submit() async {
    final strings = AppLocalizations.of(context);
    final note = _note!;
    final nameMissing = _name.text.trim().isEmpty;
    final signatureMissing = _signature.isEmpty;
    if (nameMissing || signatureMissing) {
      setState(() {
        _nameError = nameMissing ? strings.signerRequired : null;
        _signatureError = signatureMissing ? strings.signatureMissing : null;
      });
      return;
    }
    final png = await _signature.toPngBytes();
    if (png == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(deliveryNotesRepositoryProvider);
    final signed = await repository.sign(
      note: note,
      signaturePng: png,
      signerName: _name.text,
    );
    if (!mounted) return;
    if (signed case Failure(:final error)) {
      setState(() {
        _busy = false;
        _error = error;
      });
      return;
    }
    // Aktuellen Stand (mit Zeit der Unterschrift) holen und das PDF ablegen.
    final fresh = await repository.getById(note.id);
    if (!mounted) return;
    var stored = true;
    if (fresh case Success(:final value)) {
      final result = await ref
          .read(deliveryNoteDocumentsProvider)
          .storeSigned(value, _items, png);
      stored = result is Success;
    }
    if (!mounted) return;
    showSuccessSnack(
      context,
      stored ? strings.signedDone : strings.pdfNotStored,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (_loading || _note == null) {
      return AppScreen(
        title: strings.signAction,
        children: [
          if (_loading)
            const SkeletonList()
          else if (_error != null) ...[
            NoticeBanner(
              message: _error!.localized(strings),
              kind: NoticeKind.error,
            ),
            TextButton(onPressed: _load, child: Text(strings.retry)),
          ],
        ],
      );
    }
    return AppScreen(
      title: strings.signAction,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(
            '${_note!.recipientName} · ${_note!.number}',
            style: AppText.label,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Die Zeichenfläche soll Wischgesten selbst verbrauchen, damit die
        // Seite beim Unterschreiben nicht mitscrollt.
        GestureDetector(
          onVerticalDragUpdate: (_) {},
          onHorizontalDragUpdate: (_) {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(
                color: _signatureError == null
                    ? AppColors.inkMuted
                    : AppColors.error,
              ),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Stack(
              children: [
                Signature(
                  controller: _signature,
                  height: 240,
                  backgroundColor: AppColors.paper,
                ),
                if (_signature.isEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: AlignmentDirectional.topStart,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Text(strings.signHere, style: AppText.label),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_signatureError != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              top: AppSpacing.xxs,
            ),
            child: Text(
              _signatureError!,
              style: AppText.label.copyWith(color: AppColors.error),
            ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => setState(_signature.clear),
            child: Text(strings.clearSignature),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Text(strings.signConfirmText, style: AppText.body),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() => _nameError = null),
          decoration: InputDecoration(
            labelText: strings.signerName,
            errorText: _nameError,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StickyAction(
          child: PrimaryButton(
            label: strings.takeSignature,
            icon: AppIcons.signature,
            loading: _busy,
            onPressed: _submit,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.cancel,
          onPressed: _busy ? null : () => context.pop(),
        ),
      ],
    );
  }
}
