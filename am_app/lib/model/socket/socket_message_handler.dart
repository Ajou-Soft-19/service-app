import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';

class SocketMessageHandler {
  void handleAlertMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleData(parsedJson);
    debugPrint(parsedJson.toString());
  }

  void handleResponseMessage(Map<String, dynamic> parsedJson) {
    LocationSingleton().setMapMatchedLocation(parsedJson);
  }

  void handleAlertUpdateMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleDataByUpdateAlert(parsedJson);
  }

  void handleAlertEndMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().deleteVehicleData(parsedJson);
  }
}
