import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/formatting/money_formatter.dart';
import 'package:warenbestand/core/formatting/quantity_formatter.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/features/products/domain/product.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/l10n/quantity_labels.dart';
import 'package:warenbestand/shared/presentation/image_viewer_screen.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/code_text.dart';
import 'package:warenbestand/shared/widgets/display/key_value_row.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/section_header.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/display/status_label.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/layout/sticky_action.dart';

/// Produktdetail: Preise und die Aktionen am Ende (bearbeiten, deaktivieren, löschen).
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  var _contents = <ProductContent>[];
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
    final repository = ref.read(productsRepositoryProvider);
    final product = await repository.getById(widget.productId);
    if (!mounted) return;
    switch (product) {
      case Success(:final value):
        _product = value;
        if (value.unit == ProductUnit.carton) {
          final contents = await repository.contents(value.id);
          if (contents case Success(value: final lines)) _contents = lines;
        } else {
          _contents = [];
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

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) await _load();
  }

  Future<void> _toggleActive(Product product) async {
    setState(() => _busy = true);
    final result = await ref
        .read(productsRepositoryProvider)
        .setActive(product, active: !product.active);
    if (!mounted) return;
    switch (result) {
      case Success():
        setState(() => _busy = false);
        await _load();
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
    final product = _product;
    if (product == null) {
      return AppScreen(
        title: strings.productDetails,
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
    final marginText = product.marginPercent == null
        ? MoneyFormatter.format(product.margin)
        : '${MoneyFormatter.format(product.margin)} '
              '(${product.marginPercent} %)';
    return AppScreen(
      title: localizedProductName(
        name: product.name,
        nameAr: product.nameAr,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      onRefresh: _load,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CodeText(product.sku),
              if (product.category.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(child: Text(product.category, style: AppText.label)),
              ],
              if (!product.active) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusLabel(strings.inactive),
              ],
            ],
          ),
        ),
        if ((product.nameAr?.trim().isNotEmpty ?? false) &&
            product.nameAr != product.name)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              top: AppSpacing.xs,
            ),
            child: Text(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? product.name
                  : product.nameAr!,
              style: AppText.label,
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          NoticeBanner(
            message: _error!.localized(strings),
            kind: NoticeKind.error,
          ),
        ],
        if (product.imagePath != null)
          AppListRow(
            icon: AppIcons.camera,
            title: strings.viewImage,
            showChevron: true,
            onTap: () => context.push(
              '/image-viewer',
              extra: ImageViewerArgs(
                title: strings.viewImage,
                load: () => ref
                    .read(productsRepositoryProvider)
                    .downloadPhoto(product.imagePath!),
              ),
            ),
          ),
        SectionHeader(strings.pricesSection),
        ...AppListRow.divided([
          KeyValueRow(
            label: strings.buyPriceNet,
            value: MoneyFormatter.format(product.buyPrice),
          ),
          KeyValueRow(
            label: strings.sellPriceNet,
            value: MoneyFormatter.format(product.sellPrice),
          ),
          KeyValueRow(label: strings.margin, value: marginText),
        ]),
        if (product.unit == ProductUnit.carton) ...[
          SectionHeader(strings.cartonContents),
          if (_contents.isEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
              child: Text(strings.noContents, style: AppText.label),
            )
          else
            ...AppListRow.divided([
              for (final line in _contents)
                AppListRow(
                  title: line.displayName(
                    Localizations.localeOf(context).languageCode,
                  ),
                  trailing: Text(
                    QuantityFormatter.format(
                      line.quantity,
                      labels: strings.quantityLabels,
                    ),
                    style: AppText.amount,
                    textDirection: TextDirection.ltr,
                  ),
                ),
            ]),
        ],
        const SizedBox(height: AppSpacing.lg),
        StickyAction(
          child: PrimaryButton(
            label: strings.edit,
            onPressed: () => _open('/products/${product.id}/edit'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(
          label: product.active ? strings.deactivate : strings.reactivate,
          onPressed: _busy ? null : () => _toggleActive(product),
        ),
      ],
    );
  }
}
