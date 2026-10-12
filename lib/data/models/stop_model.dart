import 'package:latlong2/latlong.dart';

class BusStopModel {
  final String id;
  final String name;
  final String code;
  final LatLng location;
  final int defaultEtaMinutes;
  final String morningTiming;
  final List<String> servingBusIds;
  final bool isFavorite;

  const BusStopModel({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.defaultEtaMinutes,
    this.morningTiming = '',
    this.servingBusIds = const [],
    this.isFavorite = false,
  });

  factory BusStopModel.fromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        32.2000;
    final lng = (json['lng'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        74.1800;
    final id = (json['id'] as String?) ?? 'stop_${DateTime.now().millisecondsSinceEpoch}';
    final name = (json['name'] as String?) ?? 'Stop';
    final code = (json['code'] as String?) ??
        (name.length >= 2 ? name.substring(0, 2).toUpperCase() : 'ST');
    final morningTiming = (json['timeMorning'] as String?) ??
        (json['morningTiming'] as String?) ??
        (json['morning_timing'] as String?) ??
        '';
    final eta = (json['defaultEtaMinutes'] as num?)?.toInt() ?? 10;
    final servingBuses = (json['servingBusIds'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final isFav = (json['isFavorite'] as bool?) ?? false;

    return BusStopModel(
      id: id,
      name: name,
      code: code,
      location: LatLng(lat, lng),
      defaultEtaMinutes: eta,
      morningTiming: morningTiming,
      servingBusIds: servingBuses,
      isFavorite: isFav,
    );
  }

  BusStopModel copyWith({
    String? id,
    String? name,
    String? code,
    LatLng? location,
    int? defaultEtaMinutes,
    String? morningTiming,
    List<String>? servingBusIds,
    bool? isFavorite,
  }) {
    return BusStopModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      location: location ?? this.location,
      defaultEtaMinutes: defaultEtaMinutes ?? this.defaultEtaMinutes,
      morningTiming: morningTiming ?? this.morningTiming,
      servingBusIds: servingBusIds ?? this.servingBusIds,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
