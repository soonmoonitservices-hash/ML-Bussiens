import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/features/platform/domain/platform_tenant.dart';

/// Superadmin: Firmen auflisten, Firmen sperren oder endgültig löschen. Alles
/// prüft die Datenbank bzw. die Edge Function; nur der Superadmin kommt durch.
/// Neue Firmen legt der Superadmin über „Neuer Benutzer“ an (`UsersRepository`).
final class PlatformRepository {
  const PlatformRepository(this._client);

  final SupabaseClient _client;

  Future<Result<List<PlatformTenant>>> tenants() => guard(() async {
    final rows = await _client.rpc<List<dynamic>>('superadmin_tenants');
    return [
      for (final row in rows)
        PlatformTenant.fromJson(row as Map<String, dynamic>),
    ];
  });

  Future<Result<void>> setBlocked(String tenantId, {required bool blocked}) =>
      guard(() async {
        await _client.rpc<void>(
          'superadmin_set_blocked',
          params: {'p_tenant': tenantId, 'p_blocked': blocked},
        );
      });

  /// Löscht eine Firma mit allen Daten, Dateien und Konten. Nicht rückgängig.
  Future<Result<void>> deleteFirm(String tenantId) => guard(() async {
    await _invoke('superadmin-delete-firm', {'tenant_id': tenantId});
  });

  Future<void> _invoke(String function, Map<String, Object?> body) async {
    try {
      await _client.functions.invoke(function, body: body);
    } on FunctionException catch (error) {
      final details = error.details;
      throw PostgrestException(
        message: details is Map && details['message'] is String
            ? details['message'] as String
            : function,
      );
    }
  }
}
