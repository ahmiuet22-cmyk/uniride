class DriverModel {
  final String id;
  final String name;
  final String phone;
  final double rating;
  final String avatarUrl;

  const DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.rating,
    this.avatarUrl = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'rating': rating,
        'avatarUrl': avatarUrl,
      };

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        id: (json['id'] as String?) ?? 'drv_1',
        name: (json['name'] as String?) ?? 'Driver',
        phone: (json['phone'] as String?) ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
        avatarUrl: (json['avatarUrl'] as String?) ?? '',
      );

  DriverModel copyWith({
    String? id,
    String? name,
    String? phone,
    double? rating,
    String? avatarUrl,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
