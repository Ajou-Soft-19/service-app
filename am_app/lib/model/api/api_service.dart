import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService extends TokenApiUtils {
  final serviceServerUrl = dotenv.env['SERVICE_SERVER_URL']!;
  Future<List<LatLng>> sendCoordinates(
      double startLng,
      double startLat,
      double endLng,
      double endLat,
      int vehicleId,
      UserProvider userProvider) async {
    await checkLoginStatus(userProvider);
    print("request: $startLng, $startLng, $endLng, $endLat");
    var url = Uri.parse('$serviceServerUrl/api/navi/route');
    var body = jsonEncode({
      'source': '$startLng,$startLat',
      'dest': '$endLng,$endLat',
      'options': "",
      'provider': "OSRM",
      'vehicleId': vehicleId,
    });

    var response = await http.post(url,
        body: body, headers: await getHeaders(authRequired: true));
    print(response.body.toString());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print("response: ${response.body}");
      List<dynamic> pathPoints = jsonResponse['data']['pathPoint'];
      List<LatLng> latLngPoints = pathPoints
          .map((point) => LatLng(point['location'][1], point['location'][0]))
          .toList();

      return latLngPoints;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }
}
