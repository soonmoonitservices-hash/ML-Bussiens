import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/display/app_list_row.dart';
import 'package:warenbestand/shared/widgets/display/empty_state.dart';
import 'package:warenbestand/shared/widgets/display/skeleton_list.dart';
import 'package:warenbestand/shared/widgets/inputs/app_search_field.dart';

/// Eintrag einer Auswahl (Produkt, Fahrer, Kategorie).
final class PickOption<T> {
  const PickOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final T value;
  final String title;
  final String? subtitle;
  final String? trailing;
}

/// Öffnet eine Auswahl von unten. [loader] liefert die Einträge zur
/// Suchanfrage (leer = alle); die Funktion kennt kein Feature, damit jedes
/// Feature sie mit seinen eigenen Daten nutzen kann.
Future<T?> showPickSheet<T>(
  BuildContext context, {
  required String title,
  required Future<List<PickOption<T>>> Function(String query) loader,
  bool searchable = true,
  String? searchHint,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: AppColors.paper,
  builder: (context) => _PickSheet<T>(
    title: title,
    loader: loader,
    searchable: searchable,
    searchHint: searchHint,
  ),
);

class _PickSheet<T> extends StatefulWidget {
  const _PickSheet({
    required this.title,
    required this.loader,
    required this.searchable,
    required this.searchHint,
  });

  final String title;
  final Future<List<PickOption<T>>> Function(String query) loader;
  final bool searchable;
  final String? searchHint;

  @override
  State<_PickSheet<T>> createState() => _PickSheetState<T>();
}

class _PickSheetState<T> extends State<_PickSheet<T>> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<PickOption<T>> _options = [];
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ListView(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Text(widget.title, style: AppText.section),
          ),
          if (widget.searchable) ...[
            AppSearchField(
              controller: _search,
              hint: widget.searchHint ?? strings.search,
              onChanged: _onSearch,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (_loading)
            const SkeletonList()
          else if (_error != null)
            EmptyState(
              message: strings.unknownError,
              actionLabel: strings.retry,
              onAction: _load,
            )
          else if (_options.isEmpty)
            EmptyState(message: strings.noResults)
          else
            ...AppListRow.divided([
              for (final option in _options)
                AppListRow(
                  title: option.title,
                  subtitle: option.subtitle,
                  trailing: option.trailing == null
                      ? null
                      : Text(option.trailing!, style: AppText.amount),
                  onTap: () => Navigator.of(context).pop(option.value),
                ),
            ]),
        ],
      ),
    );
  }
}
