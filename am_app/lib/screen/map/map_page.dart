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
    // __controller.addListener(_onSearchChanged);
  }

  // Future<void> _onSearchChanged() async {
  //   if(__controller.text.isEmpty){
  //     setState((){
  //       _placesResult = [];
  //     });
  //     return;
  //   }
  //   setState(() async {
  //     _placesResult = await _searchService.searchPlaces(__controller.text);
  //
  //   });
  // }

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
            onSubmitted: (value) async {
              _placesResult = await _searchService.searchPlaces(value);
              p.PlacesSearchResult place = _placesResult.first;
              LatLng destination = LatLng(place.geometry!.location.lat, place.geometry!.location.lng);
              Marker marker = Marker(
                markerId: MarkerId(place.placeId),
                // position: destination,
                position: destination,
                infoWindow: InfoWindow(title: place.name),
              );
              setState(() {
                _markers.clear;
                _markers.add(marker);
                _controller!.moveCamera(CameraUpdate.newLatLng(destination));
              });

              Polyline route = await _mapService.drawRoute([
                LatLng(_locationData.latitude!,_locationData.longitude!), destination, LatLng(37.372443, 127.107688), LatLng(37.372446, 127.107786),LatLng(37.37244, 127.108183), LatLng(37.372411, 127.108379),
                LatLng(37.37261, 127.108536),
                LatLng(37.373226, 127.109295),
                LatLng(37.37346, 127.109625),
                LatLng(37.373574, 127.109787),
                LatLng(37.373725, 127.110002),
                LatLng(37.373845, 127.110165),
                LatLng(37.374508, 127.111075),
              ]);
              setState(() {
                _polylines.add(route);
              });
              },
            decoration: const InputDecoration(
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
              markers: _markers,
            ),
          ),
        ],
      ),
    );
  }
}
