class TenantModel {
  final String id;
  final String name;
  final String code;
  final String createdAtUtc;

  TenantModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdAtUtc,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      createdAtUtc: json['createdAtUtc']?.toString() ?? '',
    );
  }
}
