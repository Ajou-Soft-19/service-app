import 'package:google_maps_flutter/google_maps_flutter.dart';

class NavigationData {
  final int? naviPathId;
  final int? vehicleId;
  final String provider;
  final Location sourceLocation;
  final Location destLocation;
  final String queryType;
  final double distance;
  final double duration;
  final int pathPointSize;
  int currentPathPoint;
  final List<PathPoint> pathPoint;
  final List<CheckPoint>? checkPoint;
  final bool emergencyPath;

  NavigationData({
    this.naviPathId,
    this.vehicleId,
    required this.provider,
    required this.sourceLocation,
    required this.destLocation,
    required this.queryType,
    required this.distance,
    required this.duration,
    required this.pathPointSize,
    required this.currentPathPoint,
    required this.pathPoint,
    this.checkPoint,
    required this.emergencyPath,
  });

  factory NavigationData.fromJson(Map<String, dynamic> json) {
    return NavigationData(
      naviPathId: json['naviPathId'],
      vehicleId: json['vehicleId'],
      provider: json['provider'],
      sourceLocation: Location.fromJson(json['sourceLocation']),
      destLocation: Location.fromJson(json['destLocation']),
      queryType: json['queryType'],
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : json['distance'],
      duration: (json['duration'] is int)
          ? (json['duration'] as int).toDouble()
          : json['duration'],
      pathPointSize: json['pathPointSize'],
      currentPathPoint: json['currentPathPoint'],
      pathPoint: (json['pathPoint'] as List)
          .map((i) => PathPoint.fromJson(i))
          .toList(),
      checkPoint: json['checkPoint'] != null
          ? (json['checkPoint'] as List)
              .map((i) => CheckPoint.fromJson(i))
              .toList()
          : null,
      emergencyPath: json['emergencyPath'],
    );
  }

  List<LatLng> pathPointsToLatLng() {
    return pathPoint
        .map((point) =>
            LatLng(point.location.latitude, point.location.longitude))
        .toList();
  }

  CheckPoint? findNextCheckPoint() {
    for (CheckPoint cp in checkPoint!) {
      if (cp.pointIndex >= currentPathPoint) {
        return cp;
      }
    }

    return null;
  }
}

class Location {
  final double longitude;
  final double latitude;

  Location({required this.longitude, required this.latitude});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
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
  final Location location;

  PathPoint({required this.index, required this.location});

  factory PathPoint.fromJson(Map<String, dynamic> json) {
    var locationList = List<double>.from(json['location']);
    var location =
        Location(longitude: locationList[0], latitude: locationList[1]);
    return PathPoint(
      index: json['index'],
      location: location,
    );
  }
}

class CheckPoint {
  final int pointIndex;
  final Location location;
  final double distance;
  final double duration;

  CheckPoint(
      {required this.pointIndex,
      required this.location,
      required this.distance,
      required this.duration});

  factory CheckPoint.fromJson(Map<String, dynamic> json) {
    var locationList = List<double>.from(json['location']);
    var location =
        Location(longitude: locationList[0], latitude: locationList[1]);
    return CheckPoint(
      pointIndex: json['pointIndex'],
      location: location,
      distance: (json['distance'] is int)
          ? (json['distance'] as int).toDouble()
          : json['distance'],
      duration: (json['duration'] is int)
          ? (json['duration'] as int).toDouble()
          : json['duration'],
    );
  }
}
