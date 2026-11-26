import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/invoices/data/invoice_documents.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';
import 'package:warenbestand/features/invoices/presentation/invoice_status_label.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/code_text.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Rechnung ansehen: Status, Positionen, Summen und die Aktionen je Stand.
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  List<InvoiceItem> _items = const [];
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
    final repository = ref.read(invoicesRepositoryProvider);
    final invoice = await repository.getById(widget.invoiceId);
    final items = await repository.items(widget.invoiceId);
    if (!mounted) return;
    switch ((invoice, items)) {
      case (Success(value: final invoice), Success(value: final items)):
        setState(() {
          _invoice = invoice;
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

  Future<void> _showPdf(Invoice invoice) async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(invoiceDocumentsProvider);
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.showPreview,
        fileName: InvoiceDocuments.fileName(invoice),
        load: () => documents.open(invoice, _items),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _run(
    Future<Result<void>> Function() action, {
    String? success,
    bool leave = false,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return;
    switch (result) {
      case Success():
        if (success != null) showSuccessSnack(context, success);
        if (leave) {
          context.pop();
          return;
        }
        setState(() => _busy = false);
        await _load();
      case Failure(:final error):
        setState(() {
          _busy = false;
          _error = error;
        });
    }
  }

  Future<void> _confirm(
    String message,
    String label,
    Future<Result<void>> Function() action, {
    String? success,
    bool leave = false,
  }) async {
    final confirmed = await showConfirmDialog(
      context,
      message: message,
      confirmLabel: label,
    );
    if (confirmed && mounted) {
      await _run(action, success: success, leave: leave);
    }
  }

  /// Storno: Stornorechnung anlegen, ihr PDF ablegen, dann zu ihr wechseln.
  Future<void> _cancel(Invoice invoice) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.cancelInvoiceAction,
      message: strings.confirmCancelInvoice,
      confirmLabel: strings.cancelInvoiceAction,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repository = ref.read(invoicesRepositoryProvider);
    final result = await repository.cancel(invoice.id);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        final credit = await repository.getById(value);
        final items = await repository.items(value);
        if (credit is Success<Invoice> && items is Success<List<InvoiceItem>>) {
          await ref
              .read(invoiceDocumentsProvider)
              .store(credit.value, items.value);
        }
        if (!mounted) return;
        showSuccessSnack(context, strings.invoiceCancelled);
        setState(() => _busy = false);
        await context.push('/invoices/$value');
        if (mounted) await _load();
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
    final invoice = _invoice;
    if (invoice == null) {
      return AppScreen(
        title: strings.invoiceDetails,
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
    final isChef = ref.read(sessionControllerProvider).canManage;
    final labels = strings.quantityLabels;
    final usesRate7 = _items.any((i) => i.vatRate == VatRate.reduced);
    final usesRate19 = _items.any((i) => i.vatRate == VatRate.standard);
    return AppScreen(
      title: invoice.recipientName,
      onRefresh: _load,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CodeText(invoice.number ?? strings.invoiceDraftTitle),
              const SizedBox(width: AppSpacing.sm),
              InvoiceStatusLabel(invoice.status),
            ],
          ),
        ),
        if (invoice.recipientAddress.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Text(invoice.recipientAddress, style: AppText.body),
          ),
        KeyValueRow(
          label: strings.invoiceDateLabel,
          value: DateFormatter.date(invoice.date),
        ),
        KeyValueRow(
          label: strings.serviceDateLabel,
          value: DateFormatter.date(invoice.serviceDate),
        ),
        if (invoice.dueDate != null && !invoice.isCancellation)
          KeyValueRow(
            label: strings.dueDateLabel,
            value: DateFormatter.date(invoice.dueDate!),
            valueColor: invoice.status == InvoiceStatus.overdue
                ? AppColors.error
                : null,
          ),
        if (invoice.paidAt != null)
          KeyValueRow(
            label: strings.paidAtLabel,
            value: DateFormatter.date(invoice.paidAt!),
          ),
        if (invoice.deliveryNoteNumber != null)
          KeyValueRow(
            label: strings.deliveryNoteRefLabel,
            value: invoice.deliveryNoteNumber!,
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        SectionHeader(strings.positionsSection),
        ...AppListRow.divided([
          for (final item in _items)
            AppListRow(
              title: item.name,
              subtitle:
                  '${QuantityFormatter.format(item.quantity, labels: labels)}'
                  ' × ${MoneyFormatter.format(item.priceNet)}'
                  ' · ${item.vatRate.percent} %',
              trailing: Text(
                MoneyFormatter.format(item.lineNet),
                style: AppText.amount,
                textDirection: TextDirection.ltr,
              ),
            ),
        ]),
        const SizedBox(height: AppSpacing.sm),
        KeyValueRow(
          label: strings.netLabel,
          value: MoneyFormatter.format(invoice.net),
        ),
        if (!invoice.isSmallBusiness && usesRate7)
          KeyValueRow(
            label: strings.vat7Row,
            value: MoneyFormatter.format(invoice.vat7),
          ),
        if (!invoice.isSmallBusiness && usesRate19)
          KeyValueRow(
            label: strings.vat19Row,
            value: MoneyFormatter.format(invoice.vat19),
          ),
        KeyValueRow(
          label: strings.grossTotal,
          value: MoneyFormatter.format(invoice.gross),
          strong: true,
        ),
        if (invoice.note != null && invoice.note!.isNotEmpty) ...[
          SectionHeader(strings.noteLabel),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
            ),
            child: Text(invoice.note!, style: AppText.body),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ..._actions(strings, invoice, isChef: isChef),
      ],
    );
  }

  List<Widget> _actions(
    AppLocalizations strings,
    Invoice invoice, {
    required bool isChef,
  }) {
    final pdf = SecondaryButton(
      label: strings.showPdf,
      icon: AppIcons.pdf,
      onPressed: () => _showPdf(invoice),
    );
    switch (invoice.status) {
      case InvoiceStatus.draft:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.edit,
              onPressed: () => _open('/invoices/${invoice.id}/edit'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          pdf,
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirm(
                    strings.confirmDeleteDraft,
                    strings.delete,
                    () => ref
                        .read(invoicesRepositoryProvider)
                        .deleteDraft(invoice.id),
                    leave: true,
                  ),
          ),
        ];
      case InvoiceStatus.open || InvoiceStatus.overdue:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.markPaid,
              loading: _busy,
              onPressed: () => _run(
                () => ref.read(invoicesRepositoryProvider).markPaid(invoice.id),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          pdf,
          if (isChef && !invoice.isCancellation) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: strings.cancelInvoiceAction,
              onPressed: _busy ? null : () => _cancel(invoice),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirm(
                    strings.confirmDeleteInvoice,
                    strings.delete,
                    () => ref
                        .read(invoicesRepositoryProvider)
                        .deleteDraft(invoice.id),
                    leave: true,
                  ),
          ),
        ];
      case InvoiceStatus.paid:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.showPdf,
              icon: AppIcons.pdf,
              onPressed: () => _showPdf(invoice),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.markUnpaid,
            onPressed: _busy
                ? null
                : () => _run(
                    () => ref
                        .read(invoicesRepositoryProvider)
                        .markUnpaid(invoice.id),
                  ),
          ),
          if (isChef && !invoice.isCancellation) ...[
            const SizedBox(height: AppSpacing.sm),
            SecondaryButton(
              label: strings.cancelInvoiceAction,
              onPressed: _busy ? null : () => _cancel(invoice),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirm(
                    strings.confirmDeleteInvoice,
                    strings.delete,
                    () => ref
                        .read(invoicesRepositoryProvider)
                        .deleteDraft(invoice.id),
                    leave: true,
                  ),
          ),
        ];
      case InvoiceStatus.cancelled:
        return [
          StickyAction(
            child: PrimaryButton(
              label: strings.showPdf,
              icon: AppIcons.pdf,
              onPressed: () => _showPdf(invoice),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: strings.delete,
            onPressed: _busy
                ? null
                : () => _confirm(
                    strings.confirmDeleteInvoice,
                    strings.delete,
                    () => ref
                        .read(invoicesRepositoryProvider)
                        .deleteDraft(invoice.id),
                    leave: true,
                  ),
          ),
        ];
    }
  }
}
