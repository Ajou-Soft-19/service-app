import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService extends TokenApiUtils {
  final serviceServerUrl = dotenv.env['SERVICE_SERVER_URL']!;

  Future<NavigationData> getNavigationPathNoLogin(
      double startLng, double startLat, double endLng, double endLat) async {
    print("request: $startLng, $startLat, $endLng, $endLat");
    var url = Uri.parse('$serviceServerUrl/api/navi/route');
    var body = jsonEncode({
      'source': '$startLng,$startLat',
      'dest': '$endLng,$endLat',
      'options': "",
      'provider': "OSRM",
    });

    var response = await http.post(url,
        body: body, headers: await getHeaders(authRequired: true));
    print(response.body.toString());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      print("response: ${response.body}");

      NavigationData navigationData =
          NavigationData.fromJson(jsonResponse['data']);

      return navigationData;
    } else {
      throw Exception('Failed to send coordinates and receive path points');
    }
  }
}
