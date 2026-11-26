import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/drafts/form_drafts.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/date_formatter.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/ordering/product_order.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/money.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/invoices/domain/invoice.dart';
import 'package:warenbestand/features/invoices/domain/invoice_calculator.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/pdf_preview_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/draft_restored_banner.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/choice_chips.dart';
import 'package:warenbestand/shared/widgets/inputs/money_field.dart';
import 'package:warenbestand/shared/widgets/inputs/quantity_input.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';
import 'package:warenbestand/shared/widgets/sheets/product_pick_sheet.dart';

/// Eine Zeile des Formulars mit ihren Eingabefeldern.
class _LineState {
  _LineState(this.line, {required String price, String name = ''})
    : price = TextEditingController(text: price),
      name = TextEditingController(text: name);

  InvoiceDraftLine line;
  final TextEditingController price;
  final TextEditingController name;

  void dispose() {
    price.dispose();
    name.dispose();
  }
}

/// Rechnung erstellen oder (als Entwurf) bearbeiten. Empfänger frei
/// eintippen, Positionen aus Produkten oder frei, Summen live.
class InvoiceFormScreen extends ConsumerStatefulWidget {
  const InvoiceFormScreen({this.invoiceId, super.key});

  final String? invoiceId;

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _vatId = TextEditingController();
  final _note = TextEditingController();
  final _lines = <_LineState>[];
  String? _invoiceId;
  DateTime _date = DateTime.now();
  DateTime _serviceDate = DateTime.now();
  int _termDays = 14;
  bool _smallBusiness = false;
  AppError? _error;
  bool _loading = false;

  /// Merkt den angefangenen Stand auf dem Gerät (nur bei neuer Rechnung).
  late final DraftSaver _saver;
  bool _draftRestored = false;

  @override
  void initState() {
    super.initState();
    _invoiceId = widget.invoiceId;
    _saver = DraftSaver(
      drafts: ref.read(formDraftsProvider),
      form: widget.invoiceId == null ? 'invoice_new' : null,
      snapshot: _draftSnapshot,
    );
    for (final controller in [_name, _address, _vatId, _note]) {
      controller.addListener(_saver.touch);
    }
    if (widget.invoiceId == null) {
      // Sofort einsetzen, noch vor dem ersten Bild und vor dem Laden der
      // Einstellungen.
      _restoreDraft();
      _saver.start();
    }
    unawaited(_init());
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _saver.touch();
  }

  @override
  void dispose() {
    _saver.dispose();
    _name.dispose();
    _address.dispose();
    _vatId.dispose();
    _note.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  /// Der Stand zum Merken; `null`, wenn noch nichts eingegeben ist.
  Map<String, Object?>? _draftSnapshot() {
    if (_name.text.trim().isEmpty &&
        _address.text.trim().isEmpty &&
        _vatId.text.trim().isEmpty &&
        _note.text.trim().isEmpty &&
        _lines.isEmpty &&
        _invoiceId == null) {
      return null;
    }
    return {
      'invoiceId': _invoiceId,
      'name': _name.text,
      'address': _address.text,
      'vatId': _vatId.text,
      'note': _note.text,
      'date': _date.toIso8601String(),
      'serviceDate': _serviceDate.toIso8601String(),
      'lines': [
        for (final state in _lines)
          {
            'productId': state.line.productId,
            'name': state.line.isFree ? state.name.text : state.line.name,
            'unit': state.line.quantity.unit.dbValue,
            'qty': state.line.quantity.base,
            'price': state.price.text,
            'vat': state.line.vatRate.percent,
            'perCarton': state.line.unitsPerCarton,
            'sort': state.line.sortOrder,
          },
      ],
    };
  }

  /// Setzt den gemerkten Stand ein. Alle Angaben der Positionen stehen im
  /// Stand selbst, es braucht keine Abfrage.
  void _restoreDraft() {
    final draft = _saver.read();
    if (draft == null) return;
    final data = draft.data;
    try {
      _name.text = data['name'] as String? ?? '';
      _address.text = data['address'] as String? ?? '';
      _vatId.text = data['vatId'] as String? ?? '';
      _note.text = data['note'] as String? ?? '';
      // Alte Datumsangaben nicht übernehmen: dann gilt wieder heute.
      final date = DateTime.tryParse('${data['date']}');
      final serviceDate = DateTime.tryParse('${data['serviceDate']}');
      if (draft.isFromToday) {
        if (date != null) _date = date;
        if (serviceDate != null) _serviceDate = serviceDate;
      }
      _invoiceId = data['invoiceId'] as String?;
      for (final raw in data['lines'] as List<dynamic>? ?? const []) {
        final saved = raw as Map<String, dynamic>;
        final state = _LineState(
          InvoiceDraftLine(
            productId: saved['productId'] as String?,
            name: saved['name'] as String,
            unitsPerCarton: saved['perCarton'] as int?,
            sortOrder: saved['sort'] as int?,
            quantity: Quantity(
              saved['qty'] as int,
              ProductUnit.fromDb(saved['unit'] as String),
            ),
            priceNet: Money.zero,
            vatRate: VatRate.fromPercent(saved['vat'] as int),
          ),
          price: saved['price'] as String,
          name: saved['name'] as String,
        );
        state.line = state.line.copyWith(
          priceNet: MoneyField.read(state.price) ?? Money.zero,
        );
        _lines.add(state);
      }
      _draftRestored = true;
    } on Object catch (error) {
      // Unlesbarer Stand: weglassen und mit leerem Formular beginnen.
      debugPrint('Entwurf der Rechnung nicht lesbar: $error');
      _resetForm();
    }
  }

  /// Leeres Formular (ohne `setState`).
  void _resetForm() {
    _saver.clear();
    _draftRestored = false;
    _invoiceId = null;
    _name.clear();
    _address.clear();
    _vatId.clear();
    _note.clear();
    _date = DateTime.now();
    _serviceDate = DateTime.now();
    for (final line in _lines) {
      line.dispose();
    }
    _lines.clear();
    _error = null;
  }

  /// „Verwerfen“: leeres Formular, gemerkter Stand weg.
  void _discardDraft() => setState(_resetForm);

  Future<void> _init() async {
    setState(() => _loading = true);
    final repository = ref.read(invoicesRepositoryProvider);
    final settings = await repository.settings();
    if (!mounted) return;
    if (settings case Success(:final value)) {
      _termDays = value.termDays;
      _smallBusiness = value.smallBusiness;
    }
    if (_invoiceId != null) {
      final invoice = await repository.getById(_invoiceId!);
      final items = await repository.items(_invoiceId!);
      if (!mounted) return;
      switch ((invoice, items)) {
        case (Success(value: final invoice), Success(value: final items)):
          final ids = [
            for (final item in items)
              if (item.productId != null) item.productId!,
          ];
          final products = await repository.productsByIds(ids);
          if (!mounted) return;
          final byId = {
            if (products case Success(:final value))
              for (final product in value) product.id: product,
          };
          setState(() {
            _name.text = invoice.recipientName;
            _address.text = invoice.recipientAddress;
            _vatId.text = invoice.recipientVatId ?? '';
            _note.text = invoice.note ?? '';
            _date = invoice.date;
            _serviceDate = invoice.serviceDate;
            for (final item in items) {
              final perCarton = byId[item.productId]?.unitsPerCarton;
              _lines.add(
                _LineState(
                  InvoiceDraftLine(
                    productId: item.productId,
                    name: item.name,
                    unitsPerCarton: perCarton,
                    sortOrder: item.sortOrder,
                    quantity: item.quantity,
                    priceNet: item.priceNet,
                    vatRate: item.vatRate,
                  ),
                  price: MoneyFormatter.formatPlain(item.priceNet),
                  name: item.name,
                ),
              );
            }
          });
        case (Failure(:final error), _) || (_, Failure(:final error)):
          setState(() => _error = error);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  DateTime get _dueDate => _date.add(Duration(days: _termDays));

  Future<void> _pickDate({required bool service}) async {
    final initial = service ? _serviceDate : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 2),
      lastDate: DateTime(initial.year + 1),
    );
    if (picked == null) return;
    setState(() {
      if (service) {
        _serviceDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _addProduct() async {
    final strings = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final repository = ref.read(invoicesRepositoryProvider);
    final picked = await showProductPickSheet<InvoiceProduct>(
      context,
      title: strings.addProduct,
      searchHint: strings.searchProducts,
      loader: (query) async {
        final result = await repository.products(search: query);
        return switch (result) {
          Success(:final value) => [
            for (final product in value)
              ProductPickOption(
                id: product.id,
                value: product,
                title: product.displayName(language),
                subtitle: product.sku,
                unit: product.unit,
                unitsPerCarton: product.unitsPerCarton,
              ),
          ],
          Failure(:final error) => throw Exception(error.message),
        };
      },
    );
    if (picked == null || picked.isEmpty) return;
    setState(() {
      for (final pick in picked) {
        final line = pick.value.toLine().copyWith(quantity: pick.quantity);
        _lines.add(
          _LineState(line, price: MoneyFormatter.formatPlain(line.priceNet)),
        );
      }
      // Position steht dort, wo das Produkt in der Produktliste steht; freie
      // Positionen bleiben am Ende.
      final sorted = sortByProductOrder(
        _lines,
        (state) => state.line.sortOrder,
      );
      _lines
        ..clear()
        ..addAll(sorted);
    });
  }

  void _addFreeItem() => setState(
    () => _lines.add(
      _LineState(
        InvoiceDraftLine.free(
          name: '',
          unit: ProductUnit.piece,
          vatRate: _smallBusiness ? VatRate.zero : VatRate.standard,
        ),
        price: '',
      ),
    ),
  );

  /// Liest die Zeilen aus den Eingabefeldern.
  List<InvoiceDraftLine> _currentLines() => [
    for (final state in _lines)
      state.line.copyWith(
        name: state.line.isFree ? state.name.text : null,
        priceNet: MoneyField.read(state.price) ?? Money.zero,
      ),
  ];

  InvoiceTotals _totals(List<InvoiceDraftLine> lines) =>
      const InvoiceCalculator().calculate([
        for (final line in lines)
          InvoiceLine(
            quantity: line.quantity,
            priceNet: line.priceNet,
            vatRate: line.vatRate,
          ),
      ], isSmallBusiness: _smallBusiness);

  /// Speichert den Entwurf; gibt die Rechnungs-ID zurück, bei Fehler `null`.
  Future<String?> _save() async {
    final strings = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return null;
    final lines = [
      for (final line in _currentLines())
        if (line.quantity.base > 0) line,
    ];
    if (lines.isEmpty ||
        lines.any((line) => line.isFree && line.name.trim().isEmpty)) {
      setState(() => _error = DatabaseError(strings.itemsRequired));
      return null;
    }
    final input = InvoiceInput(
      recipientName: _name.text,
      recipientAddress: _address.text,
      recipientVatId: _vatId.text,
      date: _date,
      serviceDate: _serviceDate,
      dueDate: _dueDate,
      note: _note.text,
      lines: lines,
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(invoicesRepositoryProvider);
    if (_invoiceId != null) {
      final result = await repository.updateDraft(_invoiceId!, input);
      if (!mounted) return null;
      if (result case Failure(:final error)) {
        setState(() {
          _loading = false;
          _error = error;
        });
        return null;
      }
      return _invoiceId;
    }
    final result = await repository.create(input);
    if (!mounted) return null;
    switch (result) {
      case Success(:final value):
        _invoiceId = value;
        return value;
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
        return null;
    }
  }

  Future<void> _saveDraft() async {
    final id = await _save();
    if (id == null || !mounted) return;
    showSuccessSnack(context, AppLocalizations.of(context).draftSaved);
    _leave(id);
  }

  void _leave(String id) {
    if (widget.invoiceId != null) {
      UnsavedChangesGuard.disarm(context);
      context.pop();
    } else {
      _saver.finish();
      context.pushReplacement('/invoices/$id');
    }
  }

  Future<void> _preview() async {
    final id = await _save();
    if (id == null || !mounted) return;
    setState(() => _loading = false);
    final strings = AppLocalizations.of(context);
    final repository = ref.read(invoicesRepositoryProvider);
    final documents = ref.read(invoiceDocumentsProvider);
    await context.push(
      '/pdf-preview',
      extra: PdfPreviewArgs(
        title: strings.showPreview,
        fileName: 'Rechnung_Entwurf.pdf',
        load: () async {
          final invoice = await repository.getById(id);
          final items = await repository.items(id);
          return switch ((invoice, items)) {
            (Success(value: final invoice), Success(value: final items)) =>
              await documents.render(invoice, items),
            (Failure(:final error), _) ||
            (_, Failure(:final error)) => Failure(error),
          };
        },
      ),
    );
  }

  Future<void> _finalize() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: strings.finalizeAction,
      message: strings.confirmFinalize,
      confirmLabel: strings.finalizeAction,
    );
    if (!confirmed || !mounted) return;
    final id = await _save();
    if (id == null || !mounted) return;
    final repository = ref.read(invoicesRepositoryProvider);
    final result = await repository.finalize(id);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        final invoice = await repository.getById(id);
        final items = await repository.items(id);
        if (invoice is Success<Invoice> &&
            items is Success<List<InvoiceItem>>) {
          await ref
              .read(invoiceDocumentsProvider)
              .store(invoice.value, items.value);
        }
        if (!mounted) return;
        showSuccessSnack(context, strings.invoiceFinalized(value));
        _leave(id);
      case Failure(:final error):
        // Der Entwurf bleibt gespeichert; nur das Festschreiben ist gescheitert.
        setState(() {
          _loading = false;
          _error = error;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = strings.quantityLabels;
    final lines = _currentLines();
    final totals = _totals(lines);
    final usesRate7 = lines.any((l) => l.vatRate == VatRate.reduced);
    final usesRate19 = lines.any((l) => l.vatRate == VatRate.standard);
    return AppScreen(
      title: widget.invoiceId == null ? strings.newInvoice : strings.edit,
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (_draftRestored) DraftRestoredBanner(onDiscard: _discardDraft),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: strings.recipientName),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _address,
                minLines: 2,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: strings.recipientAddress,
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? strings.requiredField
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _vatId,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(labelText: strings.recipientVatId),
              ),
              SectionHeader(strings.invoiceDateLabel),
              AppListRow(
                icon: AppIcons.calendar,
                title: DateFormatter.date(_date),
                subtitle: strings.paymentTermInfo(
                  _termDays,
                  DateFormatter.date(_dueDate),
                ),
                showChevron: true,
                onTap: () => _pickDate(service: false),
              ),
              const Divider(),
              SectionHeader(strings.serviceDateLabel),
              AppListRow(
                icon: AppIcons.calendar,
                title: DateFormatter.date(_serviceDate),
                showChevron: true,
                onTap: () => _pickDate(service: true),
              ),
              const Divider(),
              SectionHeader(strings.positionsSection),
              if (_lines.isEmpty)
                EmptyState(message: strings.noItemsYet)
              else
                ...AppListRow.divided([
                  for (var i = 0; i < _lines.length; i++)
                    _lineBlock(strings, labels, i),
                ]),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: strings.addProduct,
                icon: AppIcons.add,
                onPressed: _addProduct,
              ),
              const SizedBox(height: AppSpacing.xs),
              SecondaryButton(
                label: strings.addFreeItem,
                icon: AppIcons.add,
                onPressed: _addFreeItem,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.invoiceNote),
              ),
              SectionHeader(strings.tourValues),
              if (_smallBusiness)
                NoticeBanner(
                  message: strings.smallBusinessHint,
                  kind: NoticeKind.warning,
                ),
              KeyValueRow(
                label: strings.netLabel,
                value: MoneyFormatter.format(totals.net),
              ),
              if (!_smallBusiness && usesRate7)
                KeyValueRow(
                  label: strings.vat7Row,
                  value: MoneyFormatter.format(totals.vat7),
                ),
              if (!_smallBusiness && usesRate19)
                KeyValueRow(
                  label: strings.vat19Row,
                  value: MoneyFormatter.format(totals.vat19),
                ),
              KeyValueRow(
                label: strings.grossTotal,
                value: MoneyFormatter.format(totals.gross),
                strong: true,
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
                  label: strings.finalizeAction,
                  loading: _loading,
                  onPressed: _finalize,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: strings.saveDraft,
                onPressed: _loading ? null : _saveDraft,
              ),
              const SizedBox(height: AppSpacing.sm),
              SecondaryButton(
                label: strings.showPreview,
                icon: AppIcons.pdf,
                onPressed: _loading
                    ? () => showErrorSnack(context, strings.pdfPleaseWait)
                    : _preview,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lineBlock(AppLocalizations strings, QuantityLabels labels, int i) {
    final state = _lines[i];
    final line = state.line;
    final price = MoneyField.read(state.price) ?? Money.zero;
    final total = line.quantity.valueAt(price);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: line.isFree
                    ? TextFormField(
                        controller: state.name,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: strings.freeItemName,
                        ),
                      )
                    : Text(line.name, style: AppText.bodyStrong),
              ),
              IconButton(
                tooltip: strings.remove,
                onPressed: () => setState(() {
                  _lines.removeAt(i).dispose();
                }),
                icon: const Icon(AppIcons.delete),
              ),
            ],
          ),
          if (line.isFree) ...[
            const SizedBox(height: AppSpacing.xs),
            ChoiceChips<ProductUnit>(
              selected: line.quantity.unit,
              onSelected: (unit) => setState(
                () => state.line = line.copyWith(quantity: Quantity.zero(unit)),
              ),
              options: [
                (value: ProductUnit.piece, label: strings.unitPiece),
                (value: ProductUnit.jar, label: strings.unitJar),
                (value: ProductUnit.carton, label: strings.unitCarton),
                (value: ProductUnit.kg, label: strings.unitKg),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ChoiceChips<VatRate>(
              selected: line.vatRate,
              onSelected: (rate) =>
                  setState(() => state.line = line.copyWith(vatRate: rate)),
              options: [
                for (final rate in VatRate.values)
                  (value: rate, label: '${rate.percent} %'),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          QuantityInput(
            key: ValueKey('${line.productId}-${line.quantity.unit}-$i'),
            value: line.quantity,
            unitsPerCarton: line.unitsPerCarton,
            onChanged: (value) =>
                setState(() => state.line = line.copyWith(quantity: value)),
          ),
          const SizedBox(height: AppSpacing.xs),
          MoneyField(
            controller: state.price,
            label: strings.unitPriceNetField,
            onChanged: (_) => setState(() {}),
          ),
          if (line.quantity.base > 0)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                '${QuantityFormatter.format(line.quantity, labels: labels)} · '
                '${strings.lineTotal(MoneyFormatter.format(total))}',
                style: AppText.label,
              ),
            ),
        ],
      ),
    );
  }
}
