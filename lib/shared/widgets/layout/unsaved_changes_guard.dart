import 'package:material_ui/material_ui.dart';
import 'package:warenbestand/l10n/generated/app_localizations.dart';
import 'package:warenbestand/shared/widgets/dialogs/confirm_dialog.dart';

/// Fragt beim Verlassen eines Formulars „Änderungen verwerfen?“, wenn sich ein
/// Textfeld seit der ersten Eingabe geändert hat. Nach dem Speichern ruft der
/// Screen [disarm] auf, damit das Schließen nicht noch einmal fragt.
class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({required this.child, super.key});

  final Widget child;

  /// Schaltet die Rückfrage ab (nach erfolgreichem Speichern).
  static void disarm(BuildContext context) =>
      context.findAncestorStateOfType<_GuardState>()?._armed = false;

  @override
  State<UnsavedChangesGuard> createState() => _GuardState();
}

class _GuardState extends State<UnsavedChangesGuard> {
  bool _armed = true;
  List<String>? _snapshot;

  List<String> _texts() {
    final texts = <String>[];
    void visit(Element element) {
      if (element is StatefulElement && element.state is EditableTextState) {
        texts.add((element.state as EditableTextState).widget.controller.text);
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return texts;
  }

  bool get _dirty {
    final before = _snapshot;
    if (!_armed || before == null) return false;
    final now = _texts();
    if (now.length != before.length) return true;
    for (var i = 0; i < now.length; i++) {
      if (now[i] != before[i]) return true;
    }
    return false;
  }

  Future<void> _onPop(bool didPop, Object? result) async {
    if (didPop) return;
    final strings = AppLocalizations.of(context);
    if (_dirty) {
      final leave = await showConfirmDialog(
        context,
        title: strings.discardChangesTitle,
        message: strings.discardChangesMessage,
        confirmLabel: strings.discard,
      );
      if (!leave || !mounted) return;
    }
    _armed = false;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: _onPop,
    child: Listener(
      behavior: HitTestBehavior.translucent,
      // Erste Berührung: Stand der Felder merken (Vorbelegung ist dann geladen).
      onPointerDown: (_) => _snapshot ??= _texts(),
      child: widget.child,
    ),
  );
}
