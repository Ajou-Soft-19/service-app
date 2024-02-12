import 'dart:math';

import 'package:am_app/screen/asset/assets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_singleton.dart';

class AlertSingleton {
  static final AlertSingleton _singleton = AlertSingleton._internal();

  factory AlertSingleton() {
    return _singleton;
  }

  AlertSingleton._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _licenseNumber;
  int? _currentPathPoint;
  Map<int, LatLng>? _pathPoints;

  String? get licenseNumber => _licenseNumber;
  int? get currentPathPoint => _currentPathPoint;
  Map<int, LatLng>? get pathPoints => _pathPoints;

  void updateVehicleData(String licenseNumber, int currentPathPoint, Map<int, LatLng> pathPoints) {
    _licenseNumber = licenseNumber;
    _currentPathPoint = currentPathPoint;
    _pathPoints = pathPoints;
  }

  Future<void> setLicenseNumber(String licenseNumber) async {
    await _storage.write(key: 'licenseNumber', value: licenseNumber);
    _licenseNumber = licenseNumber;
  }

  Future<bool> isExistingLicenseNumber(String licenseNumber) async {
    String? storedLicenseNumber = await _storage.read(key: 'licenseNumber');
    return storedLicenseNumber != null && storedLicenseNumber == licenseNumber;
  }
  double calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3; // metres
    var lat1 = point1.latitude * pi / 180; // φ, λ in radians
    var lat2 = point2.latitude * pi / 180;
    var deltaLat = (point2.latitude-point1.latitude) * pi / 180;
    var deltaLng = (point2.longitude-point1.longitude) * pi / 180;

    var a = sin(deltaLat/2) * sin(deltaLat/2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLng/2) * sin(deltaLng/2);
    var c = 2 * atan2(sqrt(a), sqrt(1-a));

    return R * c; // in metres
  }

  double calculateBearing(LatLng point1, LatLng point2) {
    final double lat1 = point1.latitude * pi / 180;
    final double lat2 = point2.latitude * pi / 180;
    final double lng1 = point1.longitude * pi / 180;
    final double lng2 = point2.longitude * pi / 180;

    final double y = sin(lng2 - lng1) * cos(lat2);
    final double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lng2 - lng1);
    double bearing = atan2(y, x) * 180 / pi;

    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Marker? checkAndCreateMarker() {
    LatLng currentPathPointLatLng = AlertSingleton().pathPoints![AlertSingleton().currentPathPoint!]!;
    LatLng myLatLng = LocationSingleton().currentLocLatLng;
    double distance = calculateDistance(myLatLng, currentPathPointLatLng);
    if (distance >= 1000) {
      double bearing = calculateBearing(myLatLng, currentPathPointLatLng);
      print("각도: $bearing");
      Marker marker = Marker(
        markerId: const MarkerId('emergencyMarker'),
        position: currentPathPointLatLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
      return marker;
    }
    return null;
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
