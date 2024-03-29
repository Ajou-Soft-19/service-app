import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:am_app/model/api/dto/api_response.dart';
import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/dto/vehicle_status.dart';
import 'package:am_app/model/api/dto/warn_record.dart';
import 'package:am_app/model/api/exception/exception_message.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:http/http.dart' as http;

class MonitorApi extends TokenApiUtils {
  Future<List<VehicleStatus>> getVehicleStatus(UserProvider userProvider,
      double latitude, double longitude, double radius) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);

    final url = Uri.parse('$serviceServerUrl/api/admin/monit/vehicle-status');

    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final vehicleStatuses = (json.data as List)
        .map((vehicleStatusJson) => VehicleStatus.fromJson(vehicleStatusJson))
        .toList();
    return vehicleStatuses;
  }

  Future<List<VehicleStatus>> getAllEmergencyVehicleStatus(
      UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);
    final url = Uri.parse(
        '$serviceServerUrl/api/admin/monit/vehicle-status/emergency/all');

    final response = await http
        .get(url, headers: await getHeaders(authRequired: true))
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final vehicleStatuses = (json.data as List)
        .map((vehicleStatusJson) => VehicleStatus.fromJson(vehicleStatusJson))
        .toList();
    return vehicleStatuses;
  }

  Future<NavigationData> getEmergencyNavigationPath(
      UserProvider userProvider, VehicleStatus vehicleStatus) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);
    var url = Uri.parse(
        '$serviceServerUrl/api/admin/monit/vehicle-status/emergency/route');
    var body = jsonEncode({'vehicleStatusId': vehicleStatus.vehicleStatusId});

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

  Future<int> getEmergencyVehicleCurrentCheckPoint(
      UserProvider userProvider, VehicleStatus vehicleStatus) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);
    var url = Uri.parse(
        '$serviceServerUrl/api/admin/monit/vehicle-status/emergency/currentCheckPoint');
    var body = jsonEncode({'vehicleStatusId': vehicleStatus.vehicleStatusId});

    var response = await http.post(url,
        body: body, headers: await getHeaders(authRequired: true));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      int currentPath = jsonResponse['data']['currentCheckPoint'];

      return currentPath;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }

  Future<List<WarnRecord>> getWarnRecordsByEmergencyEventId(
      UserProvider userProvider, int emergencyEventId) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/admin/monit/warn-list');

    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode({
        'emergencyEventId': emergencyEventId,
        'checkPointIndex': null,
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final warnRecords = (json.data as List)
        .map((warnRecordJson) => WarnRecord.fromJson(warnRecordJson))
        .toList();
    return warnRecords;
  }

  Future<List<WarnRecord>> getWarnRecordsByEmergencyEventIdAndCheckPointIndx(
      UserProvider userProvider,
      int emergencyEventId,
      int checkPointIndex) async {
    await checkLoginStatus(userProvider);
    await checkAdminRole(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/admin/monit/warn-list');

    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode({
        'emergencyEventId': emergencyEventId,
        'checkPointIndex': checkPointIndex,
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final warnRecords = (json.data as List)
        .map((warnRecordJson) => WarnRecord.fromJson(warnRecordJson))
        .toList();
    return warnRecords;
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
