import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/feedback/haptics.dart';
import 'package:warenbestand/core/supabase/providers.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/features/products/data/products_repository.dart';
import 'package:warenbestand/features/products/domain/product.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/app_snack.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/money_text.dart';
import 'package:warenbestand/shared/widgets/display/notice_banner.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';
import 'package:warenbestand/shared/widgets/inputs/filter_bar.dart';
import 'package:warenbestand/shared/widgets/layout/app_screen.dart';
import 'package:warenbestand/shared/widgets/sheets/pick_sheet.dart';

/// Produktliste: Suche, Filter, Kategorie. Es gibt keinen Lagerbestand; ein
/// Produkt hat Name, Einheit, Karton-Größe, Preise und Kategorie.
///
/// Ohne Suche, Filter und Kategorie steht die ganze Liste mit Nummern da. Dort
/// lassen sich die Produkte lange drücken und ziehen, oder man tippt auf die
/// Nummer und trägt die Position ein. Jede Änderung wird sofort gespeichert;
/// Touren, Lieferscheine und Rechnungen übernehmen diese Reihenfolge.
class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _items = <Product>[];
  Timer? _debounce;
  int? _count;
  ProductFilter _filter = ProductFilter.all;
  String? _category;
  AppError? _error;
  int _page = 0;
  bool _loading = false;
  bool _hasMore = true;

  /// Die Reihenfolge wird gerade gespeichert; weitere Änderungen merken sich
  /// nur, dass danach noch einmal gespeichert werden muss.
  bool _savingOrder = false;
  bool _saveAgain = false;

  /// Ganze Liste mit Nummern: nur ohne Suche, Filter und Kategorie.
  bool get _numbered =>
      _filter == ProductFilter.all &&
      _search.text.trim().isEmpty &&
      _category == null;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 300) unawaited(_load());
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  Future<void> _reload() async {
    // Während des Speicherns nicht neu laden: sonst käme kurz die alte
    // Reihenfolge zurück.
    if (_savingOrder) return;
    unawaited(_loadCount());
    await _load(reset: true);
  }

  Future<void> _loadCount() async {
    final result = await ref.read(productsRepositoryProvider).activeCount();
    if (!mounted) return;
    if (result case Success(:final value)) setState(() => _count = value);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || (!reset && !_hasMore)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repository = ref.read(productsRepositoryProvider);
    // Mit Nummern wird die ganze Liste auf einmal geladen, damit jede Nummer
    // die echte Position ist.
    if (_numbered) {
      final result = await repository.allActive();
      if (!mounted) return;
      switch (result) {
        case Success(:final value):
          setState(() {
            _items
              ..clear()
              ..addAll(value);
            _hasMore = false;
            _loading = false;
          });
        case Failure(:final error):
          setState(() {
            _error = error;
            _loading = false;
          });
      }
      return;
    }
    final nextPage = reset ? 0 : _page;
    final result = await repository.list(
      page: nextPage,
      search: _search.text,
      filter: _filter,
      category: _category,
    );
    if (!mounted) return;
    switch (result) {
      case Success(value: final rows):
        setState(() {
          if (reset) _items.clear();
          _items.addAll(rows);
          _page = nextPage + 1;
          _hasMore = rows.length == ProductsRepository.pageSize;
          _loading = false;
        });
      case Failure(:final error):
        setState(() {
          _error = error;
          _loading = false;
        });
    }
  }

  Future<void> _open(String path) async {
    await context.push<void>(path);
    if (mounted) await _reload();
  }

  Future<void> _pickCategory() async {
    final strings = AppLocalizations.of(context);
    final repository = ref.read(productsRepositoryProvider);
    final picked = await showPickSheet<String>(
      context,
      title: strings.filterCategory,
      searchable: false,
      loader: (_) async {
        final result = await repository.categories();
        final categories = switch (result) {
          Success(:final value) => value,
          Failure() => <String>[],
        };
        return [
          PickOption(value: '', title: strings.allCategories),
          for (final category in categories)
            PickOption(value: category, title: category),
        ];
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _category = picked.isEmpty ? null : picked);
    await _load(reset: true);
  }

  /// Hält die ganze Liste in der angezeigten Reihenfolge fest. Läuft nach jeder
  /// Änderung sofort, damit nichts verloren geht, wenn man die Liste verlässt.
  /// Kommt während des Speicherns eine Änderung dazu, wird danach noch einmal
  /// gespeichert (die zuletzt angezeigte Reihenfolge gewinnt).
  Future<void> _saveOrder() async {
    if (_savingOrder) {
      _saveAgain = true;
      return;
    }
    // Vor dem ersten `await` holen: Der Screen kann inzwischen verlassen sein.
    final repository = ref.read(productsRepositoryProvider);
    final strings = AppLocalizations.of(context);
    _savingOrder = true;
    AppError? failure;
    do {
      _saveAgain = false;
      final result = await repository.reorder([
        for (final item in _items) item.id,
      ]);
      if (result case Failure(:final error)) {
        failure = error;
        break;
      }
    } while (_saveAgain);
    _savingOrder = false;
    if (!mounted) return;
    if (failure == null) {
      showSuccessSnack(context, strings.reorderSaved);
      return;
    }
    showErrorSnack(context, failure.localized(strings));
    // Die gespeicherte Reihenfolge wieder anzeigen.
    await _reload();
  }

  /// Ziehen: die Anzeige ändert sich und die Reihenfolge wird sofort
  /// gespeichert. [newIndex] ist schon für das entfernte Element angepasst.
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex == oldIndex) return;
    setState(() => _items.insert(newIndex, _items.removeAt(oldIndex)));
    unawaited(_saveOrder());
  }

  /// Auf die Nummer tippen: die neue Position eintippen.
  Future<void> _askPosition(int index) async {
    final strings = AppLocalizations.of(context);
    final controller = TextEditingController(text: '${index + 1}');
    final entered = await showAdaptiveDialog<int>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(strings.reorderPositionTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            helperText: strings.reorderPositionHint(_items.length),
          ),
          onSubmitted: (value) =>
              Navigator.of(context).pop(int.tryParse(value.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (entered == null || !mounted) return;
    final target = entered.clamp(1, _items.length) - 1;
    if (target == index) return;
    setState(() => _items.insert(target, _items.removeAt(index)));
    unawaited(_saveOrder());
  }

  Widget _numberBadge(int index) => InkWell(
    onTap: () => _askPosition(index),
    borderRadius: BorderRadius.circular(AppRadius.control),
    child: Container(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.paperMuted,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Text('${index + 1}', style: AppText.bodyStrong),
    ),
  );

  Widget _rowContent(AppLocalizations strings, int index) {
    final item = _items[index];
    return AppListRow(
      icon: _numbered ? null : AppIcons.stock,
      leading: _numbered ? _numberBadge(index) : null,
      title: localizedProductName(
        name: item.name,
        nameAr: item.nameAr,
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      subtitle: [
        item.sku,
        if (item.category.isNotEmpty) item.category,
      ].join(' · '),
      trailing: MoneyText(item.sellPrice),
      showChevron: true,
      onTap: () => _open('/products/${item.id}'),
    );
  }

  Widget _reorderRow(AppLocalizations strings, int index) =>
      ReorderableDelayedDragStartListener(
        key: ValueKey(_items[index].id),
        index: index,
        child: ColoredBox(
          color: AppColors.paper,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) const Divider(),
              _rowContent(strings, index),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final count = _count;
    final searching = _search.text.trim().isNotEmpty || _category != null;
    final canReorder = _numbered && _error == null && _items.length > 1;
    return AppScreen.slivers(
      title: strings.products,
      controller: _scroll,
      onRefresh: _reload,
      actions: [
        IconButton(
          tooltip: strings.newProduct,
          onPressed: () => _open('/products/new'),
          icon: const Icon(AppIcons.add),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          sliver: SliverList.list(
            children: [
              if (count != null)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: Text(
                    strings.productCount(count),
                    style: AppText.label,
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              AppSearchField(
                controller: _search,
                hint: strings.searchProducts,
                onChanged: _onSearch,
              ),
              const SizedBox(height: AppSpacing.sm),
              FilterBar<ProductFilter>(
                selected: _filter,
                onSelected: (value) {
                  setState(() => _filter = value);
                  unawaited(_load(reset: true));
                },
                options: [
                  (value: ProductFilter.all, label: strings.filterAll),
                  (
                    value: ProductFilter.inactive,
                    label: strings.filterInactive,
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _pickCategory,
                  child: Text(
                    '${strings.filterCategory}: '
                    '${_category ?? strings.allCategories}',
                  ),
                ),
              ),
              if (canReorder)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(strings.reorderHint, style: AppText.label),
                ),
              if (_error != null) ...[
                NoticeBanner(
                  message: _error!.localized(strings),
                  kind: NoticeKind.error,
                ),
                TextButton(onPressed: _reload, child: Text(strings.retry)),
              ] else if (_items.isEmpty && !_loading)
                EmptyState(
                  message: searching || _filter != ProductFilter.all
                      ? strings.noResults
                      : strings.noProducts,
                  actionLabel: searching || _filter != ProductFilter.all
                      ? null
                      : strings.newProduct,
                  onAction: () => _open('/products/new'),
                ),
            ],
          ),
        ),
        if (_error == null && _items.isNotEmpty && _numbered)
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            sliver: SliverReorderableList(
              itemCount: _items.length,
              onReorderStart: (_) => Haptics.action(),
              // Beim Ziehen liegt das Produkt über der Liste, ohne Material
              // darunter; die Antippfläche der Zeile braucht es.
              proxyDecorator: (child, index, animation) => Material(
                color: AppColors.paper,
                elevation: 4,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: child,
              ),
              onReorderItem: _onReorder,
              itemBuilder: (context, index) => _reorderRow(strings, index),
            ),
          )
        else if (_error == null && _items.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
            ),
            sliver: SliverList.list(
              children: AppListRow.divided([
                for (var i = 0; i < _items.length; i++)
                  KeyedSubtree(
                    key: ValueKey(_items[i].id),
                    child: _rowContent(strings, i),
                  ),
              ]),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.md,
          ),
          sliver: SliverList.list(
            children: [
              if (_loading) const SkeletonList(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}
