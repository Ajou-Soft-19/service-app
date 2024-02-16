import 'dart:async';
import 'dart:math';

import 'package:am_app/screen/map/map_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/dto/alert_info.dart';

class AlertSingleton {
  static final AlertSingleton _singleton = AlertSingleton._internal();

  Map<String, Map<int, LatLng>> pathPoints = {}; // 차량 번호에 따른 경로 지점
  Map<String, int> currentPathPoint = {}; // 차량 번호에 따른 현재 경로 인덱스
  Map<String, Marker> markers = {}; // 차량 번호에 따른 마커
  Map<String, Polyline> polylines = {}; // 차량 번호에 따른 폴리라인 (경로선)

  final _controller = StreamController<String>.broadcast();

  Stream<String> get onVehicleDataUpdated => _controller.stream;

  factory AlertSingleton() {
    return _singleton;
  }

  AlertSingleton._internal();

  Future<void> updateVehicleData(Map<String, dynamic> parsedJson) async {
    Map<String, dynamic> data = parsedJson['data'];
    EmergencyPathData emergencyPathData = EmergencyPathData.fromJson(data);
    String licenseNumber = emergencyPathData.licenseNumber;
    int currentPathPointData = emergencyPathData.currentPathPoint;
    Map<int, LatLng> pathPointsData = emergencyPathData.pathPoints.map(
        (index, point) => MapEntry(
            index, LatLng(point.location.latitude, point.location.longitude)));
    currentPathPoint[licenseNumber] = currentPathPointData;
    pathPoints[licenseNumber] = pathPointsData;
    markers[licenseNumber] = Marker(
      markerId: MarkerId(licenseNumber),
      position: pathPoints[licenseNumber]![currentPathPointData]!,
    );
    List<LatLng>? emergencyPathList =
        pathPoints[licenseNumber]?.values.toList();
    polylines[licenseNumber] =
        await MapService().drawRouteRedbyId(emergencyPathList!, licenseNumber);
    _controller.sink.add(licenseNumber);
  }

  void updateVehicleDataByUpdateAlert(Map<String, dynamic> parsedJson) {
    Map<String, dynamic> data = parsedJson['data'];
    String licenseNumber = data['licenseNumber'];
    double lat = data['latitude'];
    double lng = data['longitude'];

    markers[licenseNumber] = Marker(
      markerId: MarkerId(licenseNumber),
      position: LatLng(lat, lng),
    );
    _controller.sink.add(licenseNumber);
  }

  void deleteVehicleData(Map<String, dynamic> parsedJson) {
    Map<String, dynamic> data = parsedJson['data'];
    String licenseNumber = data['licenseNumber'];

    pathPoints.remove(licenseNumber);
    currentPathPoint.remove(licenseNumber);
    markers.remove(licenseNumber);
    polylines.remove(licenseNumber);

    _controller.sink.add(licenseNumber);
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3; // metres
    var lat1 = point1.latitude * pi / 180; // φ, λ in radians
    var lat2 = point2.latitude * pi / 180;
    var deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    var deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    var a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLng / 2) * sin(deltaLng / 2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // in metres
  }

  double calculateBearing(LatLng point1, LatLng point2) {
    final double lat1 = point1.latitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double lng1 = point1.longitude * pi / 180;
    final double lng2 = point2.longitude * pi / 180;

    final double y = sin(lng2 - lng1) * cos(lat2);
    final double x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lng2 - lng1);
    double bearing = atan2(y, x) * 180 / pi;

    bearing = (bearing + 360) % 360;

    return bearing;
  }

  String determineDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) {
      return 'north';
    } else if (bearing >= 22.5 && bearing < 67.5) {
      return 'north_east';
    } else if (bearing >= 67.5 && bearing < 112.5) {
      return 'east';
    } else if (bearing >= 112.5 && bearing < 157.5) {
      return 'south_east';
    } else if (bearing >= 157.5 && bearing < 202.5) {
      return 'south';
    } else if (bearing >= 202.5 && bearing < 247.5) {
      return 'south_west';
    } else if (bearing >= 247.5 && bearing < 292.5) {
      return 'west';
    } else if (bearing >= 292.5 && bearing < 337.5) {
      return 'north_west';
    } else {
      return 'unknown';
    }
  }
}
