import 'package:am_app/model/api/dto/alert_info.dart';
import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SocketMessageHandler {
  void handleAlertMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleData(parsedJson);
  }

  void handleResponseMessage(Map<String, dynamic> parsedJson){}

  void handleAlertUpdateMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().updateVehicleDataByUpdateAlert(parsedJson);
  }

  void handleAlertEndMessage(Map<String, dynamic> parsedJson) {
    AlertSingleton().deleteVehicleData(parsedJson);
  }
}
