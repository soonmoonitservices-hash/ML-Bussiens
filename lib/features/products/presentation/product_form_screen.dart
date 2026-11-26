import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/media/photo_service.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/core/value_objects/vat_rate.dart';
import 'package:warenbestand/features/products/domain/product.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/inputs/choice_chips.dart';
import 'package:warenbestand/shared/widgets/inputs/money_field.dart';
import 'package:warenbestand/shared/widgets/inputs/quantity_input.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';
import 'package:warenbestand/shared/widgets/layout/unsaved_changes_guard.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Produkt anlegen oder bearbeiten.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({this.productId, super.key});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _nameAr = TextEditingController();
  final _contents = <ProductContent>[];
  final _category = TextEditingController();
  final _unitsPerCarton = TextEditingController();
  final _buyPrice = TextEditingController();
  final _sellPrice = TextEditingController();
  // Erst im Bearbeiten-Modus nach dem Laden gesetzt.
  late Product _product;
  Uint8List? _newPhoto;
  String? _photoPath;
  ProductUnit _unit = ProductUnit.piece;
  VatRate _vat = VatRate.reduced;
  bool _loading = false;
  AppError? _error;

  bool get _editing => widget.productId != null;

  int? get _perCarton {
    final value = int.tryParse(_unitsPerCarton.text.trim());
    return value != null && value > 0 ? value : null;
  }

  bool get _usesCartons =>
      _unit == ProductUnit.piece || _unit == ProductUnit.jar;

  @override
  void initState() {
    super.initState();
    if (_editing) unawaited(_load());
  }

  @override
  void dispose() {
    _name.dispose();
    _nameAr.dispose();
    _category.dispose();
    _unitsPerCarton.dispose();
    _buyPrice.dispose();
    _sellPrice.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(productsRepositoryProvider)
        .getById(widget.productId!);
    if (!mounted) return;
    switch (result) {
      case Success(value: final product):
        _product = product;
        _nameAr.text = product.nameAr ?? '';
        _name.text = (product.nameAr != null && product.nameAr == product.name)
            ? ''
            : product.name;
        _category.text = product.category;
        _unit = product.unit;
        _vat = product.vatRate;
        _unitsPerCarton.text = product.unitsPerCarton?.toString() ?? '';
        _buyPrice.text = MoneyFormatter.formatPlain(product.buyPrice);
        _sellPrice.text = MoneyFormatter.formatPlain(product.sellPrice);
        _photoPath = product.imagePath;
        final contents = await ref
            .read(productsRepositoryProvider)
            .contents(product.id);
        if (contents case Success(:final value)) {
          _contents
            ..clear()
            ..addAll(value);
        }
        if (!mounted) return;
        setState(() => _loading = false);
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
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

  void _changeUnit(ProductUnit unit) {
    setState(() {
      _unit = unit;
      if (!_usesCartons) _unitsPerCarton.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(productsRepositoryProvider);
    var photoPath = _photoPath;
    final photo = _newPhoto;
    if (photo != null) {
      final upload = await repository.uploadPhoto(photo);
      if (!mounted) return;
      switch (upload) {
        case Success(:final value):
          photoPath = value;
        case Failure(:final error):
          setState(() {
            _loading = false;
            _error = error;
          });
          return;
      }
    }
    final german = _name.text.trim();
    final arabic = _nameAr.text.trim();
    final input = ProductInput(
      imagePath: photoPath,
      name: german.isNotEmpty ? german : arabic,
      nameAr: arabic,
      category: _category.text,
      unit: _unit,
      unitsPerCarton: _usesCartons ? _perCarton : null,
      buyPrice: MoneyField.read(_buyPrice)!,
      sellPrice: MoneyField.read(_sellPrice)!,
      vatRate: _vat,
    );
    final result = _editing
        ? await repository.update(
            id: _product.id,
            loadedUpdatedAt: _product.updatedAt,
            input: input,
          )
        : await repository.create(input);
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        final saved = await repository.saveContents(
          value.id,
          _unit == ProductUnit.carton ? _contents : const [],
        );
        if (!mounted) return;
        if (saved case Failure(:final error)) {
          setState(() {
            _loading = false;
            _error = error;
          });
          return;
        }
        showSuccessSnack(context, AppLocalizations.of(context).saved);
        UnsavedChangesGuard.disarm(context);
        context.pop();
      case Failure(:final error):
        setState(() {
          _loading = false;
          _error = error;
        });
        if (error is ConflictError) await _showConflict(error);
    }
  }

  Future<void> _showConflict(ConflictError error) async {
    final strings = AppLocalizations.of(context);
    await showAdaptiveDialog<void>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        content: Text(error.localized(strings)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              unawaited(_load());
            },
            child: Text(strings.reload),
          ),
        ],
      ),
    );
  }

  /// Produkt zum Inhalt des Kartons hinzufügen.
  Future<void> _addContent() async {
    final strings = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final repository = ref.read(productsRepositoryProvider);
    final chosen = _contents.map((line) => line.productId).toSet();
    final picked = await showPickSheet<Product>(
      context,
      title: strings.addProduct,
      searchHint: strings.searchProducts,
      loader: (query) async {
        final result = await repository.pickable(search: query);
        return switch (result) {
          Success(:final value) => [
            for (final product in value)
              if (!chosen.contains(product.id))
                PickOption(
                  value: product,
                  title: localizedProductName(
                    name: product.name,
                    nameAr: product.nameAr,
                    languageCode: language,
                  ),
                  subtitle: product.sku,
                ),
          ],
          Failure(:final error) => throw Exception(error.message),
        };
      },
    );
    if (picked == null) return;
    setState(
      () => _contents.add(
        ProductContent(
          productId: picked.id,
          name: picked.name,
          nameAr: picked.nameAr,
          unit: picked.unit,
          unitsPerCarton: picked.unitsPerCarton,
          quantity: Quantity(1, picked.unit),
        ),
      ),
    );
  }

  List<Widget> _contentsSection(AppLocalizations strings, String language) => [
    SectionHeader(strings.cartonContents),
    Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(strings.cartonContentsHint, style: AppText.label),
    ),
    if (_contents.isEmpty)
      Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
        child: Text(strings.noContents, style: AppText.label),
      )
    else
      for (var i = 0; i < _contents.length; i++)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _contents[i].displayName(language),
                      style: AppText.bodyStrong,
                    ),
                  ),
                  IconButton(
                    tooltip: strings.remove,
                    onPressed: () => setState(() => _contents.removeAt(i)),
                    icon: const Icon(AppIcons.delete),
                  ),
                ],
              ),
              QuantityInput(
                key: ValueKey('content-${_contents[i].productId}'),
                value: _contents[i].quantity,
                unitsPerCarton: _contents[i].unitsPerCarton,
                onChanged: (value) => setState(
                  () => _contents[i] = _contents[i].withQuantity(value),
                ),
              ),
            ],
          ),
        ),
    const SizedBox(height: AppSpacing.xs),
    SecondaryButton(
      label: strings.addProduct,
      icon: AppIcons.add,
      onPressed: _addContent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final units = [
      (value: ProductUnit.carton, label: strings.unitCarton),
      (value: ProductUnit.piece, label: strings.unitPiece),
      (value: ProductUnit.jar, label: strings.unitJar),
      (value: ProductUnit.kg, label: strings.unitKg),
    ];
    return AppScreen(
      title: _editing ? strings.editProduct : strings.newProduct,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.nameGerman),
                validator: (_) =>
                    _name.text.trim().isEmpty && _nameAr.text.trim().isEmpty
                    ? strings.nameRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _nameAr,
                textDirection: TextDirection.rtl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: strings.nameArabic),
                validator: (_) =>
                    _name.text.trim().isEmpty && _nameAr.text.trim().isEmpty
                    ? strings.nameRequired
                    : null,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  top: AppSpacing.xs,
                ),
                child: Text(strings.nameHint, style: AppText.label),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _category,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: strings.categoryLabel),
              ),
              SectionHeader(strings.takePhoto),
              if (_newPhoto != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: Image.memory(_newPhoto!, fit: BoxFit.contain),
                )
              else if (_photoPath != null)
                Text(strings.viewImage, style: AppText.label),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
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
              SectionHeader(strings.unitLabel),
              ChoiceChips<ProductUnit>(
                options: units,
                selected: _unit,
                onSelected: _changeUnit,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  top: AppSpacing.xs,
                ),
                child: Text(strings.unitCartonHint, style: AppText.label),
              ),
              if (_unit == ProductUnit.carton)
                ..._contentsSection(
                  strings,
                  Localizations.localeOf(context).languageCode,
                ),
              if (_usesCartons) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _unitsPerCarton,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: strings.unitsPerCarton,
                  ),
                ),
              ],
              SectionHeader(strings.pricesSection),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Text(strings.priceHint, style: AppText.label),
              ),
              MoneyField(controller: _buyPrice, label: strings.buyPriceField),
              const SizedBox(height: AppSpacing.md),
              MoneyField(controller: _sellPrice, label: strings.sellPriceField),
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
            ],
          ),
        ),
      ],
    );
  }
}
