import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_webservice/places.dart';

class SearchService {
  late final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
  late final places = GoogleMapsPlaces(apiKey: apiKey);

  Future<List<PlacesSearchResult>> searchPlaces(String query) async {
    PlacesSearchResponse response = await places.searchByText(query);
    return response.results;
  }
}
