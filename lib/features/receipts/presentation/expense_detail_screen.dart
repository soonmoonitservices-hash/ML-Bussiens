import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/receipts/data/expense_documents.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/features/receipts/presentation/expense_category_label.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/presentation/image_viewer_screen.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Ausgabe ansehen: Daten, Beleg (Tippen = Vollbild), Bearbeiten, PDF.
class ExpenseDetailScreen extends ConsumerStatefulWidget {
  const ExpenseDetailScreen({required this.expenseId, super.key});

  final String expenseId;

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen> {
  Expense? _expense;
  AppError? _error;
  bool _loading = true;

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
    final result = await ref
        .read(expensesRepositoryProvider)
        .getById(widget.expenseId);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _expense = value;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _edit(Expense expense) async {
    await context.push('/expenses/${expense.id}/edit');
    if (mounted) await _load();
  }

  Future<void> _showImage(Expense expense) async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(expensesRepositoryProvider);
    await context.push(
      '/image-viewer',
      extra: ImageViewerArgs(
        title: strings.viewImage,
        load: () => repository.downloadPhoto(expense.imagePath!),
      ),
    );
  }

  Future<void> _sharePdf(Expense expense) async {
    final strings = AppLocalizations.of(context);
    final documents = ref.read(expenseDocumentsProvider);
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.shareAsPdf,
        fileName: ExpenseDocuments.singleFileName(expense),
        load: () => documents.single(expense),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final expense = _expense;
    if (expense == null) {
      return AppScreen(
        title: strings.expenseDetails,
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
      title: expense.title,
      onRefresh: _load,
      children: [
        KeyValueRow(
          label: strings.amountGross,
          value: MoneyFormatter.format(expense.gross),
          strong: true,
        ),
        KeyValueRow(
          label: strings.categoryLabel,
          value: expenseCategoryText(strings, expense.category),
        ),
        KeyValueRow(
          label: strings.dateLabel,
          value: DateFormatter.date(expense.date),
        ),
        if (expense.tourNumber != null)
          KeyValueRow(
            label: strings.tourNumberLabel,
            value: expense.tourNumber!,
          ),
        if (expense.note != null && expense.note!.isNotEmpty)
          KeyValueRow(label: strings.noteLabel, value: expense.note!),
        const Divider(),
        if (expense.hasReceipt)
          AppListRow(
            icon: AppIcons.expense,
            title: strings.viewImage,
            showChevron: true,
            onTap: () => _showImage(expense),
          )
        else
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Text(strings.withoutReceipt, style: AppText.label),
          ),
        const SizedBox(height: AppSpacing.lg),
        StickyAction(
          child: PrimaryButton(
            label: strings.edit,
            onPressed: () => _edit(expense),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: strings.shareAsPdf,
          icon: AppIcons.pdf,
          onPressed: () => _sharePdf(expense),
        ),
      ],
    );
  }
}
