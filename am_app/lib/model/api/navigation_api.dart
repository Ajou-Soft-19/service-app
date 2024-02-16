import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService extends TokenApiUtils {
  Future<NavigationData> getNavigationPathNoLogin(
      double startLng, double startLat, double endLng, double endLat) async {
    var url = Uri.parse('$serviceServerUrl/api/navi/route');
    var body = jsonEncode({
      'source': '$startLng,$startLat',
      'dest': '$endLng,$endLat',
      'options': "",
      'provider': "OSRM",
    });

    var response = await http.post(url,
        body: body, headers: await getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      NavigationData navigationData =
          NavigationData.fromJson(jsonResponse['data']);

      return navigationData;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }

  Future<NavigationData> getNavigationPathLogin(
      double startLng,
      double startLat,
      double endLng,
      double endLat,
      UserProvider userProvider,
      VehicleProvider vehicleProvider) async {
    await checkLoginStatus(userProvider);
    await checkEmergencyRole(userProvider);
    if (vehicleProvider.vehicleId == null) {
      throw Exception('Vehicle is not selected');
    }
    var url = Uri.parse('$serviceServerUrl/api/emergency/navi/route');
    var body = jsonEncode({
      'source': '$startLng,$startLat',
      'dest': '$endLng,$endLat',
      'options': "",
      'provider': "OSRM",
      "vehicleId": int.parse(vehicleProvider.vehicleId!),
    });

    var response = await http.post(url,
        body: body, headers: await getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      debugPrint("response: ${response.body}");

      NavigationData navigationData =
          NavigationData.fromJson(jsonResponse['data']);

      return navigationData;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }

  Future<int> registerEmergencyEvent(
      int vehicleId, int navigationPahtId, UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    await checkEmergencyRole(userProvider);
    var url = Uri.parse('$serviceServerUrl/api/emergency/event/register');
    var body = jsonEncode({
      'vehicleId': vehicleId,
      'navigationPathId': navigationPahtId,
    });

    try {
      var response = await http.post(url,
          body: body, headers: await getHeaders(authRequired: true));

      if (response.statusCode != 200) {
        debugPrint("response: ${response.body}");
        throw Exception('Failed to register emergency event');
      }

      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      return jsonResponse['data']['emergencyEventId'];
    } catch (e) {
      throw Exception('Failed to register emergency event');
    }
  }

  Future<void> endEmergencyEvent(
      int emergencyEventId, UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    await checkEmergencyRole(userProvider);
    var url = Uri.parse('$serviceServerUrl/api/emergency/event/end');
    var body = jsonEncode({
      'emergencyEventId': emergencyEventId,
    });

    try {
      var response = await http.post(url,
          body: body, headers: await getHeaders(authRequired: true));

      if (response.statusCode != 200) {
        throw Exception('Failed to end emergency event');
      }
    } catch (e) {
      throw Exception('Failed to end emergency event');
    }
  }
}
