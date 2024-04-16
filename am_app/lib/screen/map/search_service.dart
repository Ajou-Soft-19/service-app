import 'package:google_maps_webservice/places.dart';

class SearchService {
  final places = GoogleMapsPlaces(apiKey: "");

  Future<List<PlacesSearchResult>> searchPlaces(String query) async {
    PlacesSearchResponse response = await places.searchByText(query);
    return response.results;
  }
}
