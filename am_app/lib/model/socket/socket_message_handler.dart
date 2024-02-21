import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';
import 'package:synchronized/synchronized.dart';

class SocketMessageHandler {
  final _lock = Lock();

  void handleAlertMessage(Map<String, dynamic> parsedJson) async {
    await _lock.synchronized(() async {
      await AlertSingleton().updateVehicleData(parsedJson);
    });
    debugPrint(parsedJson.toString());
  }

  void handleResponseMessage(Map<String, dynamic> parsedJson) async {
    await _lock.synchronized(() async {
      LocationSingleton().setMapMatchedLocation(parsedJson);
    });
  }

  void handleAlertUpdateMessage(Map<String, dynamic> parsedJson) async {
    await _lock.synchronized(() async {
      await AlertSingleton().updateVehicleDataByUpdateAlert(parsedJson);
    });
  }

  void handleAlertEndMessage(Map<String, dynamic> parsedJson) async {
    await _lock.synchronized(() async {
      AlertSingleton().deleteVehicleData(parsedJson);
    });
  }
}
