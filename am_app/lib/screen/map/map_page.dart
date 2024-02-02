import 'dart:async';
import 'dart:math';

import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:am_app/screen/map/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as l;
import 'package:google_maps_webservice/places.dart' as p;
import 'package:provider/provider.dart';
import 'search_service.dart';
import '../../model/api/api_service.dart';
import 'map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;
  final l.Location _location = l.Location();
  final _searchService = SearchService();
  final _apiService = ApiService();
  final _mapService = MapService();
  bool _serviceEnabled = false;
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  l.LocationData _locationData =
      l.LocationData.fromMap({'latitude': 37.1234, 'longitude': 127.1234});
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {}; // Add this line
  List<p.PlacesSearchResult> _placesResult = [];
  StreamSubscription<l.LocationData>? _locationSubscription;
  bool _isUsingNavi = false;
  double _currentHeading = 0.0;

  final socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initSocketListener();
    FlutterCompass.events?.listen((CompassEvent event) {
      // debugPrint(event.toString());
      _currentHeading = event.heading!;
    });
  }

  void _initSocketListener() {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _initSocket(userProvider, vehicleProvider);
    socketService.startSendingLocationData(_locationData, _isUsingNavi);
    vehicleProvider.addListener(() {
      _initSocket(userProvider, vehicleProvider);
    });
  }

  @override
  void dispose() {
    socketService.close();
    super.dispose();
  }

  _initSocket(userProvider, vehicleProvider) async {
    if (socketService.isConnected) {
      socketService.close();
    }

    if (vehicleProvider.vehicleId == null || userProvider.accessToken == null) {
      return;
    }

    await socketService.connect(userProvider.accessToken);
    socketService.initialize(
      int.parse(vehicleProvider.vehicleId!),
    );

    // socketService.emergencyVehicleUpdates.listen((data){
    //   print('Emergency vehicle data: $data');
    // });
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
      _controller!
          .moveCamera(CameraUpdate.newCameraPosition(initialCameraPosition));
    });
  }

  void _startNavigation() {
    _locationSubscription?.cancel(); // Cancel any previous subscription

    _locationSubscription =
        _location.onLocationChanged.listen((l.LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _updateUserMarker();

        _moveCameraToCurrentLocation();
      });
      // TODO: Send location data to the server
    });
  }

  void _stopNavigation() {
    _locationSubscription?.cancel();
    _markers.clear();
    _polylines.clear();
    socketService.close();
  }

  void _updateUserMarker() async {
    BitmapDescriptor customIcon =
        await getBitmapDescriptorFromAssetBytes('assets/navigation.png', 110);

    Marker userMarker = Marker(
      markerId: const MarkerId('user'),
      position: LatLng(_locationData.latitude!, _locationData.longitude!),
      // The rotation is the direction of travel
      rotation: _currentHeading / 180 * pi,
      icon: customIcon,
    );
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'user');
      _markers.add(userMarker);

      // debugPrint("sending: ${_locationData.toString()}");
    });


  }

  void _moveCameraToCurrentLocation() {
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_locationData.latitude!, _locationData.longitude!),
          zoom: 18.0,
          bearing: _currentHeading,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    VehicleProvider vehicleProvider = Provider.of<VehicleProvider>(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajou\'s Miracle'),
        actions: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                '${_locationData.speed?.toStringAsFixed(2)} m/s',
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
          ),
          IconButton(
              onPressed: () {
                setState(() {
                  _isUsingNavi = !_isUsingNavi;
                  if (_isUsingNavi) {
                    _startNavigation();
                  } else {
                    _stopNavigation();
                  }
                });
              },
              icon: Icon(_isUsingNavi ? Icons.stop : Icons.navigation)),
          IconButton(
              onPressed: _moveCameraToCurrentLocation,
              icon: const Icon(Icons.my_location))
        ],
      ),
      body: Column(
        children: <Widget>[
          TextField(
            onSubmitted: (value) async {
              _placesResult = await _searchService.searchPlaces(value);
              p.PlacesSearchResult place = _placesResult.first;
              LatLng destination = LatLng(
                  place.geometry!.location.lat, place.geometry!.location.lng);
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
              List<LatLng> routePoints = [];
              try {
                routePoints = await _apiService.sendCoordinates(
                    _locationData.longitude!,
                    _locationData.latitude!,
                    destination.longitude,
                    destination.latitude,
                    int.parse(vehicleProvider.vehicleId!),
                    userProvider);
              } catch (e) {
                Assets().showErrorSnackBar(context, e.toString());
              }
              Polyline route = await _mapService.drawRoute(routePoints);

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
            child: Stack(children: [
              GoogleMap(
                compassEnabled: true,
                onMapCreated: (controller) {
                  _controller = controller;
                },
                initialCameraPosition: CameraPosition(
                  target:
                      LatLng(_locationData.latitude!, _locationData.longitude!),
                  zoom: 18.0,
                ),
                polylines: _polylines,
                markers: _markers,
              ),
              if (!_isUsingNavi)
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  child: FloatingActionButton(
                      child: const Icon(Icons.drive_eta),
                      onPressed: () {
                        _locationSubscription = _location.onLocationChanged
                            .listen((l.LocationData currentLocation) {
                          setState(() {
                            _locationData = currentLocation;

                            _updateUserMarker();

                            _moveCameraToCurrentLocation();
                          });
                        });
                      }),
                )
            ]),
          ),
        ],
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
