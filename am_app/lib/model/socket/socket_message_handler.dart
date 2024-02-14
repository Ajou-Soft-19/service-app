import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';

class SocketMessageHandler {
  void handleAlertMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleData(parsedJson);
  }

  void handleResponseMessage(Map<String, dynamic> parsedJson) {
    LocationSingleton().setMapMatchedLocation(parsedJson);
    debugPrint(LocationSingleton().lat.toString());
    debugPrint(LocationSingleton().lng.toString());
    debugPrint(LocationSingleton().direction.toString());
  }

  void handleAlertUpdateMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleDataByUpdateAlert(parsedJson);
  }

  void handleAlertEndMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().deleteVehicleData(parsedJson);
  }
}
