import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/core/value_objects/quantity.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/primary_button.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';

/// Produkt in der Mengenauswahl. Die Eingabefelder einer Zeile ergeben sich
/// aus Einheit und Karton-Größe: „Karton“ und „Einzeln“, bei kg „Pro
/// Kilogramm“, sonst ein Feld mit dem Namen der Einheit.
final class ProductPickOption<T> {
  const ProductPickOption({
    required this.id,
    required this.value,
    required this.title,
    required this.unit,
    required this.unitsPerCarton,
    this.subtitle,
  });

  /// Kennung des Produkts (die Eingaben bleiben über Suchanfragen erhalten).
  final String id;
  final T value;
  final String title;
  final String? subtitle;
  final ProductUnit unit;
  final int? unitsPerCarton;
}

/// Ein Produkt mit der eingetragenen Menge.
final class ProductPick<T> {
  const ProductPick({required this.value, required this.quantity});

  final T value;
  final Quantity quantity;
}

/// Öffnet die Produktauswahl von unten. Bei jedem Produkt trägt man gleich die
/// Menge ein („Karton“ und/oder „Einzeln“, bei kg „Pro Kilogramm“), beliebig
/// viele Produkte hintereinander. „Speichern“ gibt alle Produkte mit einer
/// Menge über 0 auf einmal zurück. `null`, wenn man das Fenster ohne Speichern
/// schließt.
Future<List<ProductPick<T>>?> showProductPickSheet<T>(
  BuildContext context, {
  required String title,
  required Future<List<ProductPickOption<T>>> Function(String query) loader,
  String? searchHint,
}) => showModalBottomSheet<List<ProductPick<T>>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.paper,
  builder: (context) => _ProductPickSheet<T>(
    title: title,
    loader: loader,
    searchHint: searchHint,
  ),
);

/// Die Eingabefelder eines Produkts. Bei Karton-Produkten ist [first] die
/// Zahl der Kartons und [second] die Einzelstücke, sonst ist [first] die Menge.
class _Entry<T> {
  _Entry(this.option);

  final ProductPickOption<T> option;
  final first = TextEditingController();
  final second = TextEditingController();

  /// Die eingetragene Menge, `null` bei leer oder 0.
  Quantity? get quantity {
    final perCarton = option.unitsPerCarton;
    if (perCarton != null) {
      final cartons = int.tryParse(first.text.trim()) ?? 0;
      final loose = int.tryParse(second.text.trim()) ?? 0;
      final base = cartons * perCarton + loose;
      return base > 0 ? Quantity(base, option.unit) : null;
    }
    if (option.unit.isWeight) {
      final kilograms = Quantity.tryParseKilograms(first.text);
      return kilograms != null && kilograms.base > 0 ? kilograms : null;
    }
    final pieces = int.tryParse(first.text.trim()) ?? 0;
    return pieces > 0 ? Quantity(pieces, option.unit) : null;
  }

  void dispose() {
    first.dispose();
    second.dispose();
  }
}

class _ProductPickSheet<T> extends StatefulWidget {
  const _ProductPickSheet({
    required this.title,
    required this.loader,
    required this.searchHint,
  });

  final String title;
  final Future<List<ProductPickOption<T>>> Function(String query) loader;
  final String? searchHint;

  @override
  State<_ProductPickSheet<T>> createState() => _ProductPickSheetState<T>();
}

class _ProductPickSheetState<T> extends State<_ProductPickSheet<T>> {
  final _search = TextEditingController();
  final _entries = <String, _Entry<T>>{};
  Timer? _debounce;
  List<ProductPickOption<T>> _options = [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    for (final entry in _entries.values) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final options = await widget.loader(_search.text);
      if (!mounted) return;
      setState(() {
        _options = options;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _load);
  }

  /// Die Eingabefelder eines Produkts; bleiben bei einer neuen Suche erhalten.
  _Entry<T> _entryOf(ProductPickOption<T> option) =>
      _entries.putIfAbsent(option.id, () => _Entry(option));

  /// Alle Produkte mit einer Menge, in der Reihenfolge der Auswahl.
  List<ProductPick<T>> get _picks => [
    for (final entry in _entries.values)
      if (entry.quantity case final quantity?)
        ProductPick(value: entry.option.value, quantity: quantity),
  ];

  void _confirm() => Navigator.of(context).pop(_picks);

  Widget _field(
    TextEditingController controller,
    String label, {
    required bool decimal,
    double width = 84,
  }) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      style: AppText.amount,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          decimal ? RegExp(r'^\d*[,.]?\d{0,3}') : RegExp(r'^\d*'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.sm,
        ),
      ),
      onChanged: (_) => setState(() {}),
    ),
  );

  List<Widget> _fields(AppLocalizations strings, ProductPickOption<T> option) {
    final entry = _entryOf(option);
    if (option.unitsPerCarton != null) {
      return [
        _field(entry.first, strings.unitCartonOne, decimal: false),
        const SizedBox(width: AppSpacing.xs),
        _field(entry.second, strings.loosePieces, decimal: false),
      ];
    }
    if (option.unit.isWeight) {
      return [
        _field(entry.first, strings.pickPerKilogram, decimal: true, width: 116),
      ];
    }
    final unitName = switch (option.unit) {
      ProductUnit.carton => strings.unitCartonOne,
      ProductUnit.jar => strings.unitJarOne,
      ProductUnit.piece || ProductUnit.kg => strings.unitPiece,
    };
    return [_field(entry.first, unitName, decimal: false)];
  }

  Widget _row(AppLocalizations strings, ProductPickOption<T> option) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xs,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(option.title, style: AppText.body),
              if (option.subtitle != null)
                Text(option.subtitle!, style: AppText.label),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        ..._fields(strings, option),
      ],
    ),
  );

  Widget _list(AppLocalizations strings) {
    if (_loading) return const SingleChildScrollView(child: SkeletonList());
    if (_error != null) {
      return EmptyState(
        message: strings.unknownError,
        actionLabel: strings.retry,
        onAction: _load,
      );
    }
    if (_options.isEmpty) return EmptyState(message: strings.noResults);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.md),
      children: AppListRow.divided([
        for (final option in _options) _row(strings, option),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.md + AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.md + AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(widget.title, style: AppText.section),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppSearchField(
              controller: _search,
              hint: widget.searchHint ?? strings.search,
              onChanged: _onSearch,
            ),
          ),
          Expanded(child: _list(strings)),
          if (_picks.isNotEmpty)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.page,
                AppSpacing.xs,
                AppSpacing.page,
                AppSpacing.xs +
                    (keyboardOpen ? 0 : MediaQuery.paddingOf(context).bottom),
              ),
              child: PrimaryButton(label: strings.save, onPressed: _confirm),
            ),
        ],
      ),
    );
  }
}
