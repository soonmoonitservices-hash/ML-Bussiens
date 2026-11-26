final class AppProfile {
  const AppProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
  });

  factory AppProfile.fromJson(Map<String, dynamic> json) => AppProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    active: json['active'] as bool,
  );

  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;

  bool get isChef => role == 'chef';
}
