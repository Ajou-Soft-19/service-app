import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  Future<List<LatLng>> sendCoordinates(double startLat, double startLng, double endLat, double endLng) async {
    var url = Uri.parse('YOUR_SERVER_URL');
    var body = jsonEncode({
      'start': {'lat': startLat, 'lng': startLng},
      'end': {'lat': endLat, 'lng': endLng},
    });

    var response = await http.post(url, body: body, headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      List<dynamic> pathPoints = jsonResponse['data']['pathPoints'];
      List<LatLng> latLngPoints = pathPoints.map((point) => LatLng(point[0], point[1])).toList();

      return latLngPoints;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }
}
