import 'package:supabase_flutter/supabase_flutter.dart';

final _cache = <String, String>{};

/// Stellt einem Dateipfad die Kennung der eigenen Firma voran
/// (`<firma>/2026-11/beleg.jpg`). Die Speicher-Regeln der Datenbank erlauben
/// nur Pfade der eigenen Firma. Die Kennung wird pro Benutzer gemerkt.
Future<String> tenantPath(SupabaseClient client, String path) async {
  final user = client.auth.currentUser?.id ?? '';
  var tenant = _cache[user];
  if (tenant == null) {
    tenant = await client.rpc<String>('current_tenant');
    _cache[user] = tenant;
  }
  return '$tenant/$path';
}
