import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmergencyPathData {
  final String licenseNumber;
  final String vehicleType;
  final int currentPathPoint;
  final List<PathPoint> pathPoints;

  EmergencyPathData({
    required this.licenseNumber,
    required this.vehicleType,
    required this.currentPathPoint,
    required this.pathPoints,
  });

  factory EmergencyPathData.fromJson(Map<String, dynamic> json) {
    return EmergencyPathData(
      licenseNumber: json['licenseNumber'],
      vehicleType: json['vehicleType'],
      currentPathPoint: json['currentPathPoint'],
      pathPoints: (json['pathPoints'] as List)
          .map((e) => PathPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Point {
  final double longitude;
  final double latitude;

  Point({required this.longitude, required this.latitude});

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      longitude: (json['longitude'] is int)
          ? (json['longitude'] as int).toDouble()
          : json['longitude'],
      latitude: (json['latitude'] is int)
          ? (json['latitude'] as int).toDouble()
          : json['latitude'],
    );
  }
}

class PathPoint {
  final int index;
  final Point location;

  PathPoint({required this.index, required this.location});

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    var locationList = List<double>.from(json['location']);
    var location =
    Point(longitude: locationList[0], latitude: locationList[1]);
    return PathPoint(
      index: json['index'],
      location: location,
    );
  }
}