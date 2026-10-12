import 'package:latlong2/latlong.dart';
import 'stop_model.dart';

class RouteModel {
  final String id;
  final String code; // Route A, Route B, Route C
  final String title; // University Express, City Campus, North Campus
  final List<BusStopModel> stops;
  final List<LatLng> polylinePoints;
  final int estimatedDurationMinutes;
  final int activeBusCount;
  final bool isActive;
  final String description;

  const RouteModel({
    required this.id,
    required this.code,
    required this.title,
    required this.stops,
    required this.polylinePoints,
    required this.estimatedDurationMinutes,
    required this.activeBusCount,
    this.isActive = true,
    this.description = '',
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?) ?? 'route_${DateTime.now().millisecondsSinceEpoch}';
    final code = (json['code'] as String?) ?? 'Route';
    final title = (json['title'] as String?) ?? 'Campus Transit';
    final desc = (json['description'] as String?) ?? '';
    final duration = (json['estimatedDurationMinutes'] as num?)?.toInt() ??
        (json['estimated_duration_minutes'] as num?)?.toInt() ??
        60;
    final busCount = (json['activeBusCount'] as num?)?.toInt() ??
        (json['active_bus_count'] as num?)?.toInt() ??
        1;
    final isActive = (json['isActive'] as bool?) ?? true;

    // Parse stops list
    List<BusStopModel> stopsList = [];
    if (json['stops'] is List) {
      for (final s in (json['stops'] as List)) {
        if (s is Map<String, dynamic>) {
          stopsList.add(BusStopModel.fromJson(s));
        } else if (s is Map) {
          stopsList.add(BusStopModel.fromJson(Map<String, dynamic>.from(s)));
        }
      }
    }

    // Parse polylinePoints if available in Firebase
    List<LatLng> polylineList = [];
    if (json['polylinePoints'] is List) {
      for (final p in (json['polylinePoints'] as List)) {
        if (p is List && p.length >= 2) {
          final lat = (p[0] as num).toDouble();
          final lng = (p[1] as num).toDouble();
          polylineList.add(LatLng(lat, lng));
        } else if (p is Map) {
          final lat = (p['latitude'] as num?)?.toDouble() ?? (p['lat'] as num?)?.toDouble() ?? 0.0;
          final lng = (p['longitude'] as num?)?.toDouble() ?? (p['lng'] as num?)?.toDouble() ?? 0.0;
          polylineList.add(LatLng(lat, lng));
        }
      }
    }

    return RouteModel(
      id: id,
      code: code,
      title: title,
      description: desc,
      stops: stopsList,
      polylinePoints: polylineList,
      estimatedDurationMinutes: duration,
      activeBusCount: busCount,
      isActive: isActive,
    );
  }

  RouteModel copyWith({
    String? id,
    String? code,
    String? title,
    List<BusStopModel>? stops,
    List<LatLng>? polylinePoints,
    int? estimatedDurationMinutes,
    int? activeBusCount,
    bool? isActive,
    String? description,
  }) {
    return RouteModel(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      stops: stops ?? this.stops,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      activeBusCount: activeBusCount ?? this.activeBusCount,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
    );
  }

  int get totalStops => stops.length;
}
