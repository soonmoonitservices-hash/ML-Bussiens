import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:warenbestand/core/errors/app_error.dart';
import 'package:warenbestand/core/errors/result.dart';
import 'package:warenbestand/features/drivers/domain/driver.dart';

final class DriversRepository {
  const DriversRepository(this._client);

  static const pageSize = 25;
  static const _columns = 'id,name,phone,vehicle,active,updated_at,updated_by';

  final SupabaseClient _client;

  Future<Result<List<Driver>>> list({required int page, String search = ''}) =>
      guard(() async {
        var query = _client.from('drivers').select(_columns);
        final term = search.trim();
        if (term.isNotEmpty) query = query.ilike('name', '%$term%');
        final rows = await query
            .order('created_at', ascending: false)
            .range(page * pageSize, (page + 1) * pageSize - 1);
        return rows.map(Driver.fromJson).toList(growable: false);
      });

  Future<Result<Driver>> getById(String id) => guard(() async {
    final row = await _client
        .from('drivers')
        .select(_columns)
        .eq('id', id)
        .single();
    return Driver.fromJson(row);
  });

  Future<Result<Driver>> create(DriverInput input) => guard(() async {
    final row = await _client
        .from('drivers')
        .insert(input.toJson())
        .select(_columns)
        .single();
    return Driver.fromJson(row);
  });

  Future<Result<Driver>> update({
    required String id,
    required DateTime loadedUpdatedAt,
    required DriverInput input,
  }) => guard(() async {
    final rows = await _client
        .from('drivers')
        .update(input.toJson())
        .eq('id', id)
        .eq('updated_at', loadedUpdatedAt.toUtc().toIso8601String())
        .select(_columns);
    if (rows.isEmpty) {
      throw ConflictException(await _lastEditorName(id));
    }
    return Driver.fromJson(rows.single);
  });

  Future<String?> _lastEditorName(String id) async {
    final driver = await _client
        .from('drivers')
        .select('updated_by')
        .eq('id', id)
        .maybeSingle();
    final userId = driver?['updated_by'] as String?;
    if (userId == null) return null;
    final profile = await _client
        .from('profiles')
        .select('name')
        .eq('id', userId)
        .maybeSingle();
    return profile?['name'] as String?;
  }

  Future<Result<Driver>> setActive(Driver driver, bool active) => update(
    id: driver.id,
    loadedUpdatedAt: driver.updatedAt,
    input: DriverInput(
      name: driver.name,
      phone: driver.phone,
      vehicle: driver.vehicle,
      active: active,
    ),
  );
}
