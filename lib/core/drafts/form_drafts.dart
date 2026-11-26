import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:warenbestand/core/preferences/app_preferences.dart';

/// Ein gemerkter Formularstand.
final class FormDraft {
  const FormDraft(this.data, this.savedAt, this.userId);

  final Map<String, Object?> data;
  final DateTime savedAt;

  /// Wem der Stand gehört (`null`, wenn beim Speichern niemand angemeldet war).
  final String? userId;

  /// Gespeichert am selben Kalendertag (alte Datumsangaben nicht übernehmen).
  bool get isFromToday {
    final now = DateTime.now();
    return savedAt.year == now.year &&
        savedAt.month == now.month &&
        savedAt.day == now.day;
  }
}

/// Merkt angefangene Formulare (Tour planen, Lieferschein, Rechnung), damit sie
/// nach dem Verlassen der Seite oder der App wieder da sind.
///
/// Jeder Stand liegt im Arbeitsspeicher (sofort, auch wenn das Schreiben auf
/// das Gerät noch läuft) und auf dem Gerät (übersteht das Schließen der App).
/// Er gehört dem angemeldeten Benutzer; ein anderer Benutzer sieht ihn nicht.
/// Nichts davon geht zum Server.
final class FormDrafts {
  FormDrafts(this._prefs, this._userId);

  final AppPreferences _prefs;
  final String? Function() _userId;
  final _memory = <String, FormDraft>{};

  /// Der gemerkte Stand oder `null` (nichts gemerkt, unlesbar oder von einem
  /// anderen Benutzer).
  FormDraft? read(String form) {
    final draft = _memory[form] ?? _readStored(form);
    if (draft == null) return null;
    final owner = draft.userId;
    final current = _userId();
    if (owner != null && current != null && owner != current) return null;
    return draft;
  }

  FormDraft? _readStored(String form) {
    final text = _prefs.draft(form);
    if (text == null) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return null;
      final savedAt = DateTime.tryParse('${decoded['savedAt']}');
      final data = decoded['data'];
      if (savedAt == null || data is! Map<String, dynamic>) return null;
      return FormDraft(data, savedAt.toLocal(), decoded['userId'] as String?);
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String form, Map<String, Object?> data) {
    final draft = FormDraft(data, DateTime.now(), _userId());
    _memory[form] = draft;
    try {
      return _prefs.saveDraft(
        form,
        jsonEncode({
          'savedAt': draft.savedAt.toUtc().toIso8601String(),
          'userId': draft.userId,
          'data': data,
        }),
      );
    } on Object catch (error) {
      // Im Arbeitsspeicher ist der Stand trotzdem gemerkt.
      debugPrint('Entwurf $form nicht auf dem Gerät gespeichert: $error');
      return Future.value();
    }
  }

  Future<void> clear(String form) {
    _memory.remove(form);
    return _prefs.removeDraft(form);
  }
}

/// Speichert den Stand eines Formulars kurz nach jeder Änderung und immer, wenn
/// die Seite oder die App verlassen wird.
///
/// Ablauf im Screen: [read] beim Öffnen, den Stand einsetzen, dann [start].
/// Danach bei jeder Änderung [touch]. Nach erfolgreichem Speichern auf dem
/// Server [finish], damit der Stand nicht wiederkommt.
final class DraftSaver {
  /// [form] ist `null`, wenn das Formular keinen Stand merken soll (Bearbeiten
  /// eines vorhandenen Eintrags). [snapshot] liefert den Stand oder `null`,
  /// wenn nichts eingegeben ist.
  DraftSaver({
    required this.drafts,
    required this.form,
    required this.snapshot,
  }) {
    _lifecycle = AppLifecycleListener(
      onInactive: () => flush(force: true),
      onHide: () => flush(force: true),
      onPause: () => flush(force: true),
    );
  }

  static const _delay = Duration(milliseconds: 300);

  final FormDrafts drafts;
  final String? form;
  final Map<String, Object?>? Function() snapshot;
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;
  bool _started = false;
  bool _finished = false;

  /// Das Formular merkt Stände.
  bool get enabled => form != null;

  /// Der gemerkte Stand, `null` ohne Stand oder wenn nichts gemerkt wird.
  FormDraft? read() => form == null ? null : drafts.read(form!);

  /// Ab jetzt wird gespeichert (erst nach dem Einsetzen des alten Stands,
  /// sonst würde das leere Formular ihn überschreiben).
  void start() => _started = true;

  /// Eine Änderung ist passiert; speichert gleich danach.
  void touch() {
    if (!enabled || !_started || _finished) return;
    _timer?.cancel();
    _timer = Timer(_delay, flush);
  }

  /// Speichert sofort. Ohne [force] nur, wenn eine Änderung ansteht.
  void flush({bool force = false}) {
    final form = this.form;
    if (form == null || !_started || _finished) return;
    if (!force && _timer == null) return;
    _timer?.cancel();
    _timer = null;
    final data = snapshot();
    unawaited(data == null ? drafts.clear(form) : drafts.write(form, data));
  }

  /// Vergisst den gemerkten Stand (z. B. „Verwerfen“), speichert aber weiter.
  void clear() {
    _timer?.cancel();
    _timer = null;
    final form = this.form;
    if (form != null) unawaited(drafts.clear(form));
  }

  /// Der Eintrag ist gespeichert: Stand vergessen und nichts mehr merken.
  void finish() {
    clear();
    _finished = true;
  }

  /// Beim Schließen des Screens: den aktuellen Stand immer speichern.
  void dispose() {
    flush(force: true);
    _lifecycle.dispose();
  }
}
