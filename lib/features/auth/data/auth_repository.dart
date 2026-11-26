import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/features/auth/domain/app_profile.dart';

final class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<Result<void>> signIn(String email, String password) => guard(() async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  });

  Future<Result<void>> sendRecoveryCode(String email) => guard(() async {
    await _client.auth.resetPasswordForEmail(email.trim());
  });

  Future<Result<void>> verifyRecoveryCode({
    required String email,
    required String code,
  }) => guard(() async {
    await _client.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
  });

  Future<Result<void>> updatePassword(String password) => guard(() async {
    await _client.auth.updateUser(UserAttributes(password: password));
  });

  Future<Result<void>> signOut() => guard(() => _client.auth.signOut());

  /// Ist der angemeldete Benutzer Superadmin (verwaltet alle Firmen)?
  Future<Result<bool>> isSuperadmin() => guard(() async {
    final value = await _client.rpc<bool>('is_superadmin');
    return value;
  });

  Future<Result<AppProfile>> loadProfile() => guard(() async {
    final userId = _client.auth.currentUser!.id;
    final json = await _client
        .from('profiles')
        .select('id,name,email,role,active')
        .eq('id', userId)
        .single();
    return AppProfile.fromJson(json);
  });
}
