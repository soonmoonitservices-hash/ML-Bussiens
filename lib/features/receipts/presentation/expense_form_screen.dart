import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/media/photo_service.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/receipts/domain/expense.dart';
import 'package:warenbestand/features/receipts/presentation/expense_category_label.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/presentation/image_viewer_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/choice_chips.dart';
import 'package:warenbestand/shared/widgets/inputs/money_field.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Ausgabe erfassen oder bearbeiten, mit Beleg (Foto, Galerie oder Scan).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({this.expenseId, super.key});

  final String? expenseId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _gross = TextEditingController();
  final _note = TextEditingController();
  late Expense _loaded;
  Uint8List? _newPhoto;
  String? _photoPath;
  String? _tourId;
  String? _tourNumber;
  VatRate _vat = VatRate.zero;
  String _category = ExpenseCategories.other;
  DateTime _date = DateTime.now();
  AppError? _error;
  bool _loading = false;

  bool get _editing => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) unawaited(_load());
  }

  @override
  void dispose() {
    _title.dispose();
    _gross.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await ref
        .read(expensesRepositoryProvider)
        .getById(widget.expenseId!);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _loaded = value;
          _title.text = value.title;
          _gross.text = MoneyFormatter.formatPlain(value.gross);
          _note.text = value.note ?? '';
          _vat = value.vatRate;
          _category = value.category;
          _date = value.date;
          _photoPath = value.imagePath;
          _tourId = value.tourId;
          _tourNumber = value.tourNumber;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _takePhoto(PhotoSource source) async {
    final strings = AppLocalizations.of(context);
    try {
      final bytes = await ref.read(photoServiceProvider).pick(source);
      if (bytes != null && mounted) setState(() => _newPhoto = bytes);
    } on Object {
      if (mounted) {
        setState(() => _error = DatabaseError(strings.photoFailed));
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 3),
      lastDate: DateTime(_date.year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTour() async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(expensesRepositoryProvider);
    final picked = await showPickSheet<ExpenseTour>(
      context,
      title: strings.chooseTour,
      searchable: false,
      loader: (_) async {
        final result = await repository.tours();
        return switch (result) {
          Success(:final value) => [
            for (final tour in value)
              PickOption(
                value: tour,
                title: tour.number ?? tour.driverName,
                subtitle: tour.driverName,
              ),
          ],
          Failure(:final error) => throw Exception(error.message),
        };
      },
    );
    if (picked == null) return;
    setState(() {
      _tourId = picked.id;
      _tourNumber = picked.number ?? picked.driverName;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final strings = AppLocalizations.of(context);
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(expensesRepositoryProvider);
    var path = _photoPath;
    final photo = _newPhoto;
    if (photo != null) {
      final upload = await repository.uploadPhoto(photo, _date);
      if (!mounted) return;
      switch (upload) {
        case Success(:final value):
          path = value;
        case Failure(:final error):
          setState(() {
            _loading = false;
            _error = error;
          });
          return;
      }
    }
    final input = ExpenseInput(
      date: _date,
      title: _title.text,
      category: _category,
      gross: MoneyField.read(_gross)!,
      vatRate: _vat,
      tourId: _tourId,
      note: _note.text,
      imagePath: path,
    );
    final result = _editing
        ? await repository.update(_loaded, input)
        : await repository.create(input);
    if (!mounted) return;
    switch (result) {
      case Success():
        showSuccessSnack(context, strings.saved);
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  Future<void> _delete() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      message: strings.confirmDeleteExpense,
      confirmLabel: strings.delete,
    );
    if (!confirmed || !mounted) return;
    setState(() => _loading = true);
    final result = await ref
        .read(expensesRepositoryProvider)
        .delete(_loaded.id);
    if (!mounted) return;
    switch (result) {
      case Success():
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final hasPhoto = _newPhoto != null || _photoPath != null;
    return AppScreen(
      title: _editing ? strings.edit : strings.newExpense,
      children: [
        SectionHeader(strings.takePhoto),
        if (_newPhoto != null)
          _preview(Image.memory(_newPhoto!, fit: BoxFit.contain))
        else if (_photoPath != null)
          _ExistingPhoto(path: _photoPath!),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            SecondaryButton(
              label: strings.scanReceipt,
              icon: AppIcons.camera,
              onPressed: () => _takePhoto(PhotoSource.scanner),
            ),
            SecondaryButton(
              label: strings.takePhoto,
              icon: AppIcons.camera,
              onPressed: () => _takePhoto(PhotoSource.camera),
            ),
            SecondaryButton(
              label: strings.pickFromGallery,
              onPressed: () => _takePhoto(PhotoSource.gallery),
            ),
          ],
        ),
        if (hasPhoto)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() {
                _newPhoto = null;
                _photoPath = null;
              }),
              child: Text(strings.removePhoto),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.expenseTitle),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              MoneyField(
                controller: _gross,
                label: strings.amountGross,
                onChanged: (_) => setState(() {}),
              ),
              SectionHeader(strings.categoryLabel),
              ChoiceChips<String>(
                options: [
                  for (final category in ExpenseCategories.all)
                    (
                      value: category,
                      label: expenseCategoryText(strings, category),
                    ),
                ],
                selected: _category,
                onSelected: (value) => setState(() => _category = value),
              ),
              SectionHeader(strings.dateLabel),
              AppListRow(
                icon: AppIcons.calendar,
                title: DateFormatter.date(_date),
                showChevron: true,
                onTap: _pickDate,
              ),
              const Divider(),
              SectionHeader(strings.tourOptional),
              AppListRow(
                icon: AppIcons.tour,
                title: _tourNumber ?? strings.noTour,
                showChevron: true,
                onTap: _pickTour,
              ),
              const Divider(),
              if (_tourId != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _tourId = null;
                      _tourNumber = null;
                    }),
                    child: Text(strings.noTour),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.noteLabel),
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
                  label: strings.save,
                  loading: _loading,
                  onPressed: _save,
                ),
              ),
              if (_editing) ...[
                const SizedBox(height: AppSpacing.sm),
                SecondaryButton(
                  label: strings.delete,
                  onPressed: _loading ? null : _delete,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _preview(Widget image) => ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 280),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: image,
      ),
    ),
  );
}

/// Vorschau eines schon gespeicherten Belegs; Tippen öffnet den Vollbild.
class _ExistingPhoto extends ConsumerWidget {
  const _ExistingPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(expensesRepositoryProvider);
    return AppListRow(
      icon: AppIcons.expense,
      title: strings.viewImage,
      showChevron: true,
      onTap: () => context.push(
        '/image-viewer',
        extra: ImageViewerArgs(
          title: strings.viewImage,
          load: () => repository.downloadPhoto(path),
        ),
      ),
    );
  }
}
