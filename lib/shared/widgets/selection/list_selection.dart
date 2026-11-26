import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:warenbestand/core/theme/app_theme.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/buttons/secondary_button.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';

/// Auswahlmodus einer Liste (Touren, Lieferscheine, Rechnungen): Ein/Aus und
/// die gewählten Einträge nach Kennung.
class ListSelection<T> extends ChangeNotifier {
  bool _active = false;
  final _items = <String, T>{};

  /// Ist der Auswahlmodus an?
  bool get active => _active;

  /// Anzahl gewählter Einträge.
  int get count => _items.length;

  /// Die gewählten Einträge.
  List<T> get values => _items.values.toList();

  bool isSelected(String id) => _items.containsKey(id);

  void toggleMode() {
    _active = !_active;
    if (!_active) _items.clear();
    notifyListeners();
  }

  void toggle(String id, T item) {
    if (_items.containsKey(id)) {
      _items.remove(id);
    } else {
      _items[id] = item;
    }
    notifyListeners();
  }

  /// Alle gezeigten Einträge wählen; sind schon alle gewählt, alle abwählen.
  void toggleAll(Map<String, T> shown) {
    final all = shown.keys.every(_items.containsKey);
    if (all) {
      shown.keys.forEach(_items.remove);
    } else {
      _items.addAll(shown);
    }
    notifyListeners();
  }

  /// Nach dem Löschen: Auswahl leeren, Modus bleibt.
  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool allSelected(Iterable<String> shown) =>
      shown.isNotEmpty && shown.every(_items.containsKey);
}

/// Leiste über der Liste im Auswahlmodus: Anzahl, „Alle auswählen“, Teilen
/// und Löschen.
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    required this.count,
    required this.allSelected,
    required this.onToggleAll,
    required this.onShare,
    required this.onDelete,
    this.busy = false,
    super.key,
  });

  final int count;
  final bool allSelected;
  final VoidCallback onToggleAll;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final enabled = count > 0 && !busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(strings.selectionCount(count), style: AppText.label),
            ),
            TextButton(
              onPressed: onToggleAll,
              child: Text(
                allSelected ? strings.deselectAll : strings.selectAll,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: strings.share,
                icon: AppIcons.share,
                onPressed: enabled ? onShare : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SecondaryButton(
                label: strings.delete,
                icon: AppIcons.delete,
                onPressed: enabled ? onDelete : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Fragt vor dem Löschen mehrerer Einträge nach; [extraWarning] kommt dazu
/// (z. B. bei festgeschriebenen Rechnungen).
Future<bool> confirmDeleteMany(
  BuildContext context,
  int count, {
  String? extraWarning,
}) {
  final strings = AppLocalizations.of(context);
  return showConfirmDialog(
    context,
    title: strings.deleteManyTitle(count),
    message: [strings.confirmDeleteMany, ?extraWarning].join('\n\n'),
    confirmLabel: strings.delete,
  );
}

/// Eine fertige PDF-Datei zum Teilen.
typedef PdfShareFile = ({String name, Uint8List bytes});

/// Teilt mehrere PDFs auf einmal (Mail, Nachrichten, Dateien …).
Future<void> sharePdfFiles(List<PdfShareFile> files) =>
    SharePlus.instance.share(
      ShareParams(
        files: [
          for (final file in files)
            XFile.fromData(
              file.bytes,
              mimeType: 'application/pdf',
              name: file.name,
            ),
        ],
        fileNameOverrides: [for (final file in files) file.name],
      ),
    );
