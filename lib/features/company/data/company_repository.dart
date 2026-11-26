import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/core/supabase/tenant_path.dart';
import 'package:warenbestand/features/company/domain/company_settings.dart';

/// Firmendaten lesen und speichern (Speichern darf nur der Chef; die
/// Datenbank prüft das).
final class CompanyRepository {
  const CompanyRepository(this._client);

  final SupabaseClient _client;

  Future<Result<CompanySettings>> load() => guard(() async {
    final row = await _client
        .from('company_settings')
        .select(CompanySettings.columns)
        .single();
    return CompanySettings.fromJson(row);
  });

  Future<Result<CompanySettings>> save(CompanySettings settings) =>
      guard(() async {
        final row = await _client
            .from('company_settings')
            .update(settings.toJson())
            .eq('id', true)
            .select(CompanySettings.columns)
            .single();
        return CompanySettings.fromJson(row);
      });

  /// Legt die gespeicherte Unterschrift der Firma ab (ersetzt die alte).
  Future<Result<void>> saveSignature(Uint8List png) => guard(() async {
    final path = await tenantPath(
      _client,
      'company/signature-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await _client.storage
        .from('signatures')
        .uploadBinary(
          path,
          png,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );
    await _client
        .from('company_settings')
        .update({'signature_path': path})
        .eq('id', true);
  });

  /// Entfernt die gespeicherte Unterschrift der Firma.
  Future<Result<void>> removeSignature() => guard(() async {
    await _client
        .from('company_settings')
        .update({'signature_path': null})
        .eq('id', true);
  });

  Future<Result<Uint8List>> downloadSignature(String path) =>
      guard(() => _client.storage.from('signatures').download(path));
}
