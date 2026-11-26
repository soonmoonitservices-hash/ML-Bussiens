import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/features/auth/domain/app_profile.dart';

/// Benutzerliste für den Chef. Neue Benutzer legt der Betreiber im
/// Supabase-Dashboard an (kein Einladungs-Ablauf in der App).
final class UsersRepository {
  const UsersRepository(this._client);

  final SupabaseClient _client;

  Future<Result<List<AppProfile>>> list() => guard(() async {
    final rows = await _client
        .from('profiles')
        .select('id,name,email,role,active')
        .order('name');
    return rows.map(AppProfile.fromJson).toList(growable: false);
  });

  Future<Result<void>> update(String id, {String? role, bool? active}) =>
      guard(() async {
        await _client
            .from('profiles')
            .update({'role': ?role, 'active': ?active})
            .eq('id', id);
      });

  Future<Result<void>> rename(String id, String name) => guard(() async {
    await _client.from('profiles').update({'name': name.trim()}).eq('id', id);
  });

  /// Legt einen Benutzer an (Edge Function `create-user`): in der eigenen
  /// Firma, oder mit [company] in einer eigenen, neuen Firma (nur der
  /// Superadmin; der Server prüft das).
  Future<Result<void>> createUser({
    required String name,
    required String email,
    required String password,
    String? company,
  }) => guard(() async {
    try {
      final response = await _client.functions.invoke(
        'create-user',
        body: {
          'name': name,
          'email': email,
          'password': password,
          if (company != null) ...{'mode': 'new_company', 'company': company},
        },
      );
      // Eine ältere Server-Fassung kennt „neue Firma“ nicht und hätte den
      // Benutzer in die eigene Firma gelegt: das nicht stillschweigend lassen.
      final data = response.data;
      if (company != null && !(data is Map && data['mode'] == 'new_company')) {
        throw const PostgrestException(
          message:
              'Der Server ist noch nicht aktualisiert. Der Benutzer wurde '
              'in deiner eigenen Firma angelegt.',
        );
      }
    } on FunctionException catch (error) {
      final details = error.details;
      throw PostgrestException(
        message: details is Map && details['message'] is String
            ? details['message'] as String
            : 'create-user',
      );
    }
  });

  /// Löscht das eigene Konto über die Edge Function `delete-account`.
  Future<Result<void>> deleteOwnAccount() => guard(() async {
    try {
      await _client.functions.invoke('delete-account');
    } on FunctionException catch (error) {
      final details = error.details;
      throw PostgrestException(
        message: details is Map && details['message'] is String
            ? details['message'] as String
            : 'delete-account',
      );
    }
  });
}
