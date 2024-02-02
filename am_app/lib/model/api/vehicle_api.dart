import 'dart:async';
import 'dart:convert';

import 'package:am_app/model/api/dto/api_response.dart';
import 'package:am_app/model/api/dto/vehicle.dart';
import 'package:am_app/model/api/exception/exception_message.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class VehicleApi extends TokenApiUtils {
  final serviceServerUrl = dotenv.env['SERVICE_SERVER_URL']!;

  Future<List<Vehicle>> getVehicleInfo(UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/vehicles/all');
    final response = await http
        .get(url, headers: await getHeaders(authRequired: true))
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);

    final json = ApiResponse.fromJson(utf8.decode(response.bodyBytes));
    final vehicles = (json.data as List)
        .map((vehicleJson) => Vehicle.fromJson(vehicleJson))
        .toList();
    return vehicles;
  }

  Future<void> registerVehicle(String countryCode, String licenseNumber,
      String vehicleType, UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/vehicles');
    final response = await http
        .post(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode(<String, String>{
        'countryCode': countryCode,
        'licenceNumber': licenseNumber,
        'vehicleType': vehicleType,
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
  }

  Future<void> deleteVehicle(int vehicleId, UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/vehicles/$vehicleId');
    final response = await http
        .delete(url, headers: await getHeaders(authRequired: true))
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
  }

  Future<void> updateVehicle(int vehicleId, String countryCode,
      String vehicleType, UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    final url = Uri.parse('$serviceServerUrl/api/vehicles/$vehicleId');
    final response = await http
        .put(
      url,
      headers: await getHeaders(authRequired: true),
      body: jsonEncode(<String, String>{
        'countryCode': countryCode,
        'vehicleType': vehicleType,
      }),
    )
        .timeout(timeoutTime, onTimeout: () {
      throw TimeoutException(ExceptionMessage.SERVER_NOT_RESPONDING);
    });

    await isResponseSuccess(response);
  }
}
