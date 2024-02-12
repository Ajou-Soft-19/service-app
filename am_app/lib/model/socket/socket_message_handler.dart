import 'package:am_app/model/api/dto/alert_info.dart';
import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SocketMessageHandler {
  void handleAlertMessage(Map<String, dynamic> parsedJson) {
    if (parsedJson['code'] != 200) return;
    if (parsedJson['messageType'] != 'ALERT') return;
    Map<String, dynamic> data = parsedJson['data'];
    debugPrint("$data");
    EmergencyPathData emergencyPathData = EmergencyPathData.fromJson(data);

    Map<int, LatLng> pathPoints = emergencyPathData.pathPoints.map(
        (index, point) => MapEntry(
            index, LatLng(point.location.latitude, point.location.longitude)));

    AlertSingleton().updateVehicleData(emergencyPathData.licenseNumber,
        emergencyPathData.currentPathPoint, pathPoints);

    debugPrint('License Number: ${AlertSingleton().licenseNumber}');
    debugPrint('Vehicle Type: ${emergencyPathData.vehicleType}');
    debugPrint('Current Path Point: ${AlertSingleton().currentPathPoint}');
    debugPrint(
        'Path Points: ${AlertSingleton().pathPoints?.entries.map((e) => 'index: ${e.key}, location: ${e.value}').join(', ')}');
    debugPrint(
        'Current distance between Emer: ${AlertSingleton().calculateDistance(AlertSingleton().pathPoints![AlertSingleton().currentPathPoint!]!, LocationSingleton().currentLocLatLng)}');
  }

  void handleResponseMessage(Map<String, dynamic> parsedJson) {}

  void handleAlertUpdateMessage(Map<String, dynamic> parsedJson) {}

  void handleAlertEndMessage(Map<String, dynamic> parsedJson) {}
}
