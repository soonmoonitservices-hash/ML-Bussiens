/// Eine Firma in der Superadmin-Liste.
final class PlatformTenant {
  const PlatformTenant({
    required this.id,
    required this.name,
    required this.blocked,
    required this.userCount,
    required this.chefName,
    required this.chefEmail,
  });

  factory PlatformTenant.fromJson(Map<String, dynamic> json) => PlatformTenant(
    id: json['id'] as String,
    name: json['name'] as String,
    blocked: json['blocked'] as bool,
    userCount: json['user_count'] as int,
    chefName: json['chef_name'] as String?,
    chefEmail: json['chef_email'] as String?,
  );

  final String id;
  final String name;
  final bool blocked;
  final int userCount;
  final String? chefName;
  final String? chefEmail;
}
