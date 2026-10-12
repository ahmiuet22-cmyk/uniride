class SpecialShuttleModel {
  final String id;
  final String busId;
  final String busName;
  final String routeId;
  final String routeName;
  final String origin;
  final String destination;
  final double? originLat;
  final double? originLng;
  final double? destinationLat;
  final double? destinationLng;
  final String purpose;
  final String startTime;
  final String endTime;
  final String date;
  final String status;
  final String driverName;
  final int createdAt;

  SpecialShuttleModel({
    required this.id,
    required this.busId,
    required this.busName,
    required this.routeId,
    required this.routeName,
    this.origin = 'RCET Campus Terminal',
    required this.destination,
    this.originLat,
    this.originLng,
    this.destinationLat,
    this.destinationLng,
    required this.purpose,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.status,
    required this.driverName,
    required this.createdAt,
  });

  factory SpecialShuttleModel.fromJson(Map<String, dynamic> json) {
    final routeVal = json['route']?.toString() ?? json['route_name']?.toString() ?? json['routeName']?.toString() ?? json['destination']?.toString() ?? 'Special Campus Route';
    return SpecialShuttleModel(
      id: json['id']?.toString() ?? '',
      busId: json['bus_id']?.toString() ?? json['busId']?.toString() ?? '',
      busName: json['bus_name']?.toString() ?? json['busName']?.toString() ?? 'Special Bus',
      routeId: json['route_id']?.toString() ?? json['routeId']?.toString() ?? '',
      routeName: routeVal,
      origin: json['origin']?.toString() ?? json['from']?.toString() ?? json['fromName']?.toString() ?? 'RCET Campus',
      destination: json['destination']?.toString() ?? json['to']?.toString() ?? json['toName']?.toString() ?? routeVal,
      originLat: (json['origin_lat'] as num?)?.toDouble() ?? (json['fromLat'] as num?)?.toDouble(),
      originLng: (json['origin_lng'] as num?)?.toDouble() ?? (json['fromLng'] as num?)?.toDouble(),
      destinationLat: (json['destination_lat'] as num?)?.toDouble() ?? (json['toLat'] as num?)?.toDouble(),
      destinationLng: (json['destination_lng'] as num?)?.toDouble() ?? (json['toLng'] as num?)?.toDouble(),
      purpose: json['purpose']?.toString() ?? 'Special Campus Shuttle',
      startTime: json['start_time']?.toString() ?? json['startTime']?.toString() ?? '12:00',
      endTime: json['end_time']?.toString() ?? json['endTime']?.toString() ?? '14:00',
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      driverName: json['driver_name']?.toString() ?? json['driverName']?.toString() ?? 'Assigned Staff',
      createdAt: (json['created_at'] as num?)?.toInt() ??
          (json['createdAt'] as num?)?.toInt() ??
          int.tryParse(json['created_at']?.toString() ?? '') ??
          int.tryParse(json['createdAt']?.toString() ?? '') ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_id': busId,
      'bus_name': busName,
      'route_id': routeId,
      'route_name': routeName,
      'origin': origin,
      'destination': destination,
      'origin_lat': originLat,
      'origin_lng': originLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'purpose': purpose,
      'start_time': startTime,
      'end_time': endTime,
      'date': date,
      'status': status,
      'driver_name': driverName,
      'created_at': createdAt,
    };
  }

  // --- Precise Time-Window Lifecycle Engine ---

  /// Parses departure date and time into a DateTime object
  DateTime? get departureDateTime {
    try {
      final now = DateTime.now();
      int year = now.year;
      int month = now.month;
      int day = now.day;

      final trimmedDate = date.trim();
      if (trimmedDate.isNotEmpty && trimmedDate.toLowerCase() != 'today') {
        final parsed = DateTime.tryParse(trimmedDate);
        if (parsed != null) {
          year = parsed.year;
          month = parsed.month;
          day = parsed.day;
        } else {
          final parts = trimmedDate.split(RegExp(r'[-/.]'));
          if (parts.length == 3) {
            if (parts[0].length == 4) {
              year = int.tryParse(parts[0]) ?? year;
              month = int.tryParse(parts[1]) ?? month;
              day = int.tryParse(parts[2]) ?? day;
            } else if (parts[2].length == 4) {
              day = int.tryParse(parts[0]) ?? day;
              month = int.tryParse(parts[1]) ?? month;
              year = int.tryParse(parts[2]) ?? year;
            }
          }
        }
      }

      int hour = 0;
      int minute = 0;
      if (startTime.isNotEmpty) {
        String t = startTime.trim().toUpperCase();
        final bool isPm = t.contains('PM');
        final bool isAm = t.contains('AM');
        t = t.replaceAll(RegExp(r'[^\d:]'), '');
        final timeParts = t.split(':');
        if (timeParts.isNotEmpty) {
          hour = int.tryParse(timeParts[0]) ?? 0;
          if (timeParts.length > 1) {
            minute = int.tryParse(timeParts[1]) ?? 0;
          }
          if (isPm && hour < 12) hour += 12;
          if (isAm && hour == 12) hour = 0;
        }
      }

      var dt = DateTime(year, month, day, hour, minute);

      // Rollover to tomorrow ONLY if scheduled departure was already in the past relative to creation time
      // (e.g. transport officer at 10 PM schedules a 7:30 AM morning shuttle)
      if (createdAt > 0) {
        final createdDt = DateTime.fromMillisecondsSinceEpoch(createdAt);
        if (dt.isBefore(createdDt.subtract(const Duration(minutes: 5)))) {
          dt = dt.add(const Duration(days: 1));
        }
      }

      return dt;
    } catch (_) {
      return null;
    }
  }

  /// Whether the special shuttle departure time has arrived/passed or was ended
  bool get isExpired {
    final s = status.toLowerCase();
    if (s == 'completed' || s == 'expired' || s == 'cancelled') {
      return true;
    }
    final dt = departureDateTime;
    if (dt != null) {
      return DateTime.now().isAfter(dt);
    }
    return false;
  }

  /// Formatted departure time (e.g., "08:30 AM" or "02:15 PM")
  String get formattedDepartureTime {
    if (startTime.isEmpty) return 'On Schedule';
    final upper = startTime.toUpperCase();
    if (upper.contains('AM') || upper.contains('PM')) {
      return startTime;
    }
    final parts = startTime.trim().split(':');
    if (parts.isNotEmpty) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final period = h >= 12 ? 'PM' : 'AM';
      final displayHour = h % 12 == 0 ? 12 : h % 12;
      final displayMin = m.toString().padLeft(2, '0');
      return '${displayHour.toString().padLeft(2, '0')}:$displayMin $period';
    }
    return startTime;
  }

  /// Friendly countdown text until departure
  String get timeUntilDeparture {
    final dt = departureDateTime;
    if (dt == null) return formattedDepartureTime;
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) return 'Departed';
    if (diff.inDays > 0) {
      return 'In ${diff.inDays}d ${diff.inHours % 24}h';
    } else if (diff.inHours > 0) {
      return 'In ${diff.inHours}h ${diff.inMinutes % 60}m';
    } else if (diff.inMinutes > 0) {
      return 'In ${diff.inMinutes} mins';
    } else {
      return 'Departing now';
    }
  }

  /// Whether the special shuttle is currently running right now
  bool get isRunningNow => !isExpired;

  /// Whether the special shuttle is scheduled for a future time
  bool get isUpcoming => !isExpired;

  /// Returns friendly status label
  String get statusBadgeLabel {
    if (isExpired) return 'COMPLETED';
    return 'SPECIAL SHUTTLE';
  }

  /// Returns time remaining / start countdown text
  String get timingDescription {
    if (isExpired) {
      return 'Trip Concluded';
    }
    return formattedDepartureTime;
  }

  bool get isActive => !isExpired;
}
