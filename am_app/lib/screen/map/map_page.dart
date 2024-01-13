import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as l;
import 'package:google_maps_webservice/places.dart' as p;
import 'search_service.dart';
import 'api_service.dart';
import 'map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;
  final __controller = TextEditingController();
  final l.Location _location = l.Location();
  Marker? _currentMarker;
  final _searchService = SearchService();
  final _apiService = ApiService();
  final _mapService = MapService();
  bool _serviceEnabled = false;
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  l.LocationData _locationData = l.LocationData.fromMap({'latitude': 37.1234, 'longitude':127.1234});
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};  // Add this line

  List<p.PlacesSearchResult> _placesResult = [];

  @override
  void initState() {
    super.initState();
    _getLocation();
    __controller.addListener(_onSearchChanged);
  }

  Future<void> _onSearchChanged() async {
    if(__controller.text.isEmpty){
      setState((){
        _placesResult = [];
      });
      return;
    }
    _placesResult = await _searchService.searchPlaces(__controller.text);
  }

  _getLocation() async {
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == l.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != l.PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await _location.getLocation();
    final initialCameraPosition = CameraPosition(
      target: LatLng(_locationData.latitude!, _locationData.longitude!),
      zoom: 18.0,
    );

    setState(() {
      _controller!.moveCamera(CameraUpdate.newCameraPosition(initialCameraPosition));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: __controller,
            decoration: InputDecoration(
              labelText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          Flexible(
            child: GoogleMap(
              onMapCreated: (controller) {
                _controller = controller;
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(_locationData.latitude!, _locationData.longitude!),
                zoom: 18.0,
              ),
              polylines: _polylines,
              markers: _markers,  // Add this line
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: () async {
          // // Search for a location
          // List<p.PlacesSearchResult> results = await _searchService.searchPlaces('아주대학교 병원');

          if (_placesResult.isNotEmpty) {
            // Get the first result
            p.PlacesSearchResult place = _placesResult.first;

            // Create a LatLng object
            LatLng destination = LatLng(place.geometry!.location.lat, place.geometry!.location.lng);
            // _apiservice 로 _locationData.lat, lng 보내고, place.lat, lng 보내면 됨
            // Move the camera to the destination
            _controller!.moveCamera(CameraUpdate.newLatLng(destination));//destination 들어가있엇어

            // Create a marker
            Marker marker = Marker(
              markerId: MarkerId(place.placeId),
              // position: destination,
              position: destination,
              infoWindow: InfoWindow(title: place.name),
            );

            // Update polylines and markers
            setState(() async {
              // List<LatLng> routePoints = await _apiService.sendCoordinates(37.5665, 126.9780, 37.5775, 126.9770);

              // _polylines.add(await _mapService.drawRoute(routePoints));
              _polylines.add(await _mapService.drawRoute([
              destination, LatLng(37.372443, 127.107688), LatLng(37.372446, 127.107786),LatLng(37.37244, 127.108183), LatLng(37.372411, 127.108379),
              LatLng(37.37261, 127.108536),
              LatLng(37.373226, 127.109295),
              LatLng(37.37346, 127.109625),
              LatLng(37.373574, 127.109787),
              LatLng(37.373725, 127.110002),
              LatLng(37.373845, 127.110165),
              LatLng(37.374508, 127.111075),
              LatLng(37.37527, 127.112118),
              LatLng(37.375369, 127.112257),
              LatLng(37.375476, 127.112399),
              LatLng(37.375566, 127.112529),
              LatLng(37.377113, 127.114721),
              LatLng(37.377291, 127.114974),
              LatLng(37.377997, 127.11596),
              LatLng(37.379758, 127.118422),
              LatLng(37.379899, 127.118621),
              LatLng(37.38005, 127.118828),
              LatLng(37.380292, 127.119161),
              LatLng(37.380873, 127.119962),
              LatLng(37.381982, 127.12164),
              LatLng(37.382132, 127.121869),
              LatLng(37.384023, 127.124432),
              LatLng(37.384266, 127.124764),
              LatLng(37.384396, 127.124972),
              LatLng(37.384616, 127.12535),
              LatLng(37.384891, 127.125716),
              LatLng(37.385166, 127.126076),
              LatLng(37.385403, 127.126343),
              LatLng(37.385716, 127.126668),
              LatLng(37.385784, 127.126729),
              LatLng(37.385847, 127.126829)]));
              _markers.add(marker);  // Add this line
            });
          }
        },
      ),
    );
  }
}
