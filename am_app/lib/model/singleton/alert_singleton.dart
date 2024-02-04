import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertSingleton {
  static final AlertSingleton _singleton = AlertSingleton._internal();

  factory AlertSingleton() {
    return _singleton;
  }

  AlertSingleton._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _licenseNumber;
  int? _currentPathPoint;
  List<LatLng>? _pathPoints;

  String? get licenseNumber => _licenseNumber;
  int? get currentPathPoint => _currentPathPoint;
  List<LatLng>? get pathPoints => _pathPoints;

  void updateVehicleData(String licenseNumber, int currentPathPoint, List<LatLng> pathPoints) {
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

}
