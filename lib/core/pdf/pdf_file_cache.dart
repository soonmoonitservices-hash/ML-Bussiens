import 'dart:io';
import 'dart:typed_data';

/// Lokaler Cache für festgeschriebene PDFs (Rechnungen, unterschriebene
/// Lieferscheine). Sie ändern sich nie, darum öffnen sie beim zweiten Mal ohne
/// Download. Der Schlüssel ist der Speicherpfad in Supabase. Fehler beim
/// Lesen oder Schreiben werden still ignoriert: der Cache ist nur eine
/// Beschleunigung.
abstract final class PdfFileCache {
  /// Obergrenze; darüber werden die ältesten Dateien gelöscht.
  static const int maxBytes = 200 * 1024 * 1024;

  static Directory get _directory => Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}pdf_cache',
  );

  static File _file(String key) => File(
    '${_directory.path}${Platform.pathSeparator}'
    '${key.replaceAll(RegExp('[^A-Za-z0-9._-]'), '_')}',
  );

  /// Das gespeicherte PDF oder `null`.
  static Future<Uint8List?> read(String key) async {
    try {
      final file = _file(key);
      return file.existsSync() ? await file.readAsBytes() : null;
    } on Object {
      return null;
    }
  }

  /// Legt das PDF ab und räumt bei Bedarf auf.
  static Future<void> write(String key, Uint8List bytes) async {
    try {
      await _directory.create(recursive: true);
      await _file(key).writeAsBytes(bytes, flush: true);
      await _trim();
    } on Object {
      // Ohne Cache geht es nur langsamer.
    }
  }

  static Future<void> _trim() async {
    final files = <File>[
      await for (final entity in _directory.list())
        if (entity is File) entity,
    ];
    var total = 0;
    final stats = <File, FileStat>{};
    for (final file in files) {
      final stat = file.statSync();
      stats[file] = stat;
      total += stat.size;
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => stats[a]!.modified.compareTo(stats[b]!.modified));
    for (final file in files) {
      if (total <= maxBytes) break;
      total -= stats[file]!.size;
      await file.delete();
    }
  }
}
