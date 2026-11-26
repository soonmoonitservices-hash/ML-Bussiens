import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/delivery_notes/data/delivery_note_documents.dart';
import 'package:warenbestand/features/delivery_notes/domain/delivery_note.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/code_text.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Lieferschein ansehen: Daten, Positionen und die Aktionen je nach Stand.
class DeliveryNoteDetailScreen extends ConsumerStatefulWidget {
  const DeliveryNoteDetailScreen({required this.noteId, super.key});

  final String noteId;

  @override
  ConsumerState<DeliveryNoteDetailScreen> createState() =>
      _DeliveryNoteDetailScreenState();
}

class _DeliveryNoteDetailScreenState
    extends ConsumerState<DeliveryNoteDetailScreen> {
  DeliveryNote? _note;
  List<DeliveryNoteItem> _items = const [];
  AppError? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
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

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _load();
  }

  Future<void> _showPdf(DeliveryNote note) async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(deliveryNoteDocumentsProvider);
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.showPreview,
        fileName: DeliveryNoteDocuments.fileName(note),
        load: () => documents.open(note, _items),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete(DeliveryNote note) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      message: note.isSigned
          ? strings.confirmDeleteSignedNote
          : strings.confirmDeleteNote,
      confirmLabel: strings.delete,
    );
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(deliveryNotesRepositoryProvider)
        .delete(note.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        context.pop();
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  Future<void> _createInvoice(DeliveryNote note) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(deliveryNotesRepositoryProvider)
        .invoiceFromNote(note.id);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() => _busy = false);
        await context.push('/invoices/$value');
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final note = _note;
    if (note == null) {
      return AppScreen(
        title: strings.deliveryNoteDetails,
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
    final labels = strings.quantityLabels;
    return AppScreen(
      title: note.recipientName,
      onRefresh: _load,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CodeText(note.number),
              const SizedBox(width: AppSpacing.sm),
              if (note.isSigned)
                StatusLabel(
                  strings.statusSigned,
                  color: AppColors.success,
                  surface: AppColors.successSurface,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (note.recipientAddress.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Text(note.recipientAddress, style: AppText.body),
          ),
        KeyValueRow(
          label: strings.dateLabel,
          value: DateFormatter.date(note.date),
        ),
        if (note.tourNumber != null)
          KeyValueRow(label: strings.tourNumberLabel, value: note.tourNumber!),
        if (note.isSigned)
          KeyValueRow(
            label: strings.statusSigned,
            value: strings.signedBy(
              note.signerName ?? '',
              DateFormatter.dateTime(note.signedAt!),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        SectionHeader(strings.products),
        ...AppListRow.divided([
          for (final item in _items)
            AppListRow(
              title: item.name,
              trailing: Text(
                QuantityFormatter.format(item.quantity, labels: labels),
                style: AppText.amount,
                textDirection: TextDirection.ltr,
              ),
            ),
        ]),
        if (note.note != null && note.note!.isNotEmpty) ...[
          SectionHeader(strings.noteLabel),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
            ),
            child: Text(note.note!, style: AppText.body),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        // Kein Unterschreiben-Schritt mehr: Die Unterschrift des Inhabers kommt
        // aus den Firmendaten, der Fahrer unterschreibt nach dem Ausdruck.
        StickyAction(
          child: PrimaryButton(
            label: strings.showPdf,
            icon: AppIcons.pdf,
            onPressed: () => _showPdf(note),
          ),
        ),
        if (!note.isSigned) ...[
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.edit,
            onPressed: () => _open('/delivery-notes/${note.id}/edit'),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.createInvoiceFromNote,
          icon: AppIcons.invoice,
          onPressed: _busy ? null : () => _createInvoice(note),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.delete,
          onPressed: _busy ? null : () => _delete(note),
        ),
      ],
    );
  }
}
