final class Driver {
  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.active,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String?,
    vehicle: json['vehicle'] as String?,
    active: json['active'] as bool,
    updatedAt: DateTime.parse(json['updated_at'] as String),
    updatedBy: json['updated_by'] as String?,
  );

  final String id;
  final String name;
  final String? phone;
  final String? vehicle;
  final bool active;
  final DateTime updatedAt;
  final String? updatedBy;
}

final class DriverInput {
  const DriverInput({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.active,
  });

  final String name;
  final String? phone;
  final String? vehicle;
  final bool active;

  Map<String, Object?> toJson() => {
    'name': name.trim(),
    'phone': _nullable(phone),
    'vehicle': _nullable(vehicle),
    'active': active,
  };

  static String? _nullable(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
