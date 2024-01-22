import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  Future<List<LatLng>> sendCoordinates(double startLng, double startLat, double endLng, double endLat) async {
    print("request: $startLng, $startLng, $endLng, $endLat");
    var url = Uri.parse('http://35.216.118.43:7001/api/navi/route');
    var body = jsonEncode({
      'source': '$startLng,$startLat',
      'dest': '$endLng,$endLat',
      'options': "",
      'provider':"OSRM",
      'vehicleId': 1,
    });

    var response = await http.post(url, body: body, headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJrbWtra3BAbmF2ZXIuY29tIiwiYXV0aCI6IlJPTEVfVVNFUiIsInVzZXJuYW1lIjoi6rmA66-86recIiwidG9rZW5JZCI6ImE4N2JjOTY1LWZjZjYtNDJhZi1iOTZiLWM0MWViMDdkODcxYiIsImV4cCI6MTcwNTg0NDI0OH0.b3uiELwNXfCCALN2jVNjO9jMZETceUhPvVWa34CXYw4_Hh-1h4O_s38B5S1DgzsLyDF6TndYZnpjQKJVfcXcmw"
    });
    print(response.body.toString());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print("response: ${response.body}");
      List<dynamic> pathPoints = jsonResponse['data']['pathPoint'];
      List<LatLng> latLngPoints = pathPoints.map((point) => LatLng(point['location'][1], point['location'][0])).toList();

      return latLngPoints;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }
}
