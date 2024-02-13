import 'dart:async';
import 'dart:math';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:am_app/model/socket/socket_connector.dart';
import 'package:am_app/screen/login/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as l;
import 'package:google_maps_webservice/places.dart' as p;
import 'package:provider/provider.dart';
import 'custom_google_map.dart';
import 'search_service.dart';
import '../../model/api/navigation_api.dart';
import 'map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  GoogleMapController? _controller;

  final l.Location _location = l.Location();
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  l.LocationData _locationData =
      l.LocationData.fromMap({'latitude': 37.1234, 'longitude': 127.1234});
  StreamSubscription<l.LocationData>? _locationSubscription;

  final _searchService = SearchService();
  final _apiService = ApiService();
  final _mapService = MapService();
  final socketService = SocketConnector();
  bool _isLoaded = false;
  bool _serviceEnabled = false;
  bool _isUsingNavi = false;
  bool _isSearching = false;
  bool _isStickyButtonPressed = true;

  final TextEditingController _searchController = TextEditingController();
  NavigationData? navigationData;
  double _currentHeading = 0.0;

  List<p.PlacesSearchResult> _placesResult = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    initListeners();
  }

  void initListeners() async {
    await _getLocation();
    await _initSocketListener();
    await _initCompassListener();
    await attachUserMarkerChanger();
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> _initSocketListener() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    await socketService.initSocket();
    vehicleProvider.addListener(() {
      socketService.initSocket();
    });
    socketService.startSendingLocationData(_location);
  }

  Future<void> _initCompassListener() {
    FlutterCompass.events?.listen((CompassEvent event) {
      _currentHeading = event.heading!;
      socketService.setDirection(_currentHeading);
    });

    return Future(() => null);
  }

  Future<void> attachUserMarkerChanger() {
    _locationSubscription =
        _location.onLocationChanged.listen((l.LocationData currentLocation) {
      setState(() {
        _locationData = currentLocation;
        _updateUserMarker();
        _moveCameraToCurrentLocation();
      });
    });
    return Future(() => null);
  }

  @override
  void dispose() {
    socketService.close();
    super.dispose();
  }

  Future<void> _getLocation() async {
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
    _moveCameraToCurrentLocation();
  }

  void _startNavigation() {
    socketService.setUsingNavi(true);
    AlertSingleton().onVehicleDataUpdated.listen((licenseNumber) {
      setState(() {
        _isStickyButtonPressed = true;
        _moveCameraToCurrentLocation();

        if (AlertSingleton().markers.containsKey(licenseNumber)) {
          _markers
              .removeWhere((marker) => marker.markerId.value == licenseNumber);
          _markers.add(AlertSingleton().markers[licenseNumber]!);
        }

        // Polyline 추가
        if (AlertSingleton().polylines.containsKey(licenseNumber)) {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == licenseNumber);
          _polylines.add(AlertSingleton().polylines[licenseNumber]!);
        }

        // Marker와 Polyline 삭제
        if (!AlertSingleton().markers.containsKey(licenseNumber)) {
          _markers
              .removeWhere((marker) => marker.markerId.value == licenseNumber);
        }
        if (!AlertSingleton().polylines.containsKey(licenseNumber)) {
          _polylines.removeWhere(
              (polyline) => polyline.polylineId.value == licenseNumber);
        }
        LatLng? currentPathPointLatLng =
            AlertSingleton().markers[licenseNumber]?.position;
        LatLng myLatLng = LocationSingleton().currentLocLatLng;
        String direction = AlertSingleton().determineDirection(AlertSingleton()
                .calculateBearing(myLatLng, currentPathPointLatLng!) -
            _currentHeading);
        debugPrint(direction);
        Alignment alignment;
        switch (direction) {
          case 'north':
            alignment = Alignment.topCenter;
            break;
          case 'north_east':
            alignment = Alignment.topRight;
            break;
          case 'east':
            alignment = Alignment.centerRight;
            break;
          case 'south_east':
            alignment = Alignment.bottomRight;
            break;
          case 'south':
            alignment = Alignment.bottomCenter;
            break;
          case 'south_west':
            alignment = Alignment.bottomLeft;
            break;
          case 'west':
            alignment = Alignment.centerLeft;
            break;
          case 'north_west':
            alignment = Alignment.topLeft;
            break;
          default:
            alignment = Alignment.center;
            break;
        }
        debugPrint(alignment.toString());
        debugPrint(direction);
        Assets().showWhereEmergency(context, alignment, direction);
      });
    });
  }

  void _stopNavigation() {
    _isUsingNavi = false;
    socketService.setUsingNavi(false);
    _markers.clear();
    _polylines.clear();
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
    });
  }

  void _moveCameraToCurrentLocation() async {
    if (_isStickyButtonPressed == false || _isSearching) return;

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: LatLng(_locationData.latitude!, _locationData.longitude!),
            zoom: 18.0,
            bearing: _currentHeading,
            tilt: 50.0),
      ),
    );
  }

  void _searchDestination(String value) async {
    LatLng destination;
    try {
      destination = await searchPlace(value);
    } catch (e) {
      debugPrint(e.toString());
      Assets().showErrorSnackBar(context, 'Failed to search destination.');
      return;
    }
    Marker marker = Marker(
      markerId: const MarkerId('destination'),
      position: destination,
      infoWindow: InfoWindow(title: value),
    );
    setState(() {
      _markers.add(marker);
      _controller!.moveCamera(CameraUpdate.newLatLng(destination));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLoaded) {
        Assets().showLoadingDialog(context, "Loading...");
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          buildGoogleMap(),
          buildSearchRow(),
          buildPlacesResults(),
        ],
      ),
    );
  }

  Widget buildSearchRow() {
    var height = MediaQuery.of(context).size.height;
    return Positioned(
      top: height * 0.025,
      left: 20.0,
      right: 10.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.25),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _searchController,
                onSubmitted: (value) async {
                  _searchDestination(_searchController.text);
                  _isSearching = true;
                  setState(() {});
                },
                decoration: InputDecoration(
                  prefixIcon: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingPage()),
                      );
                    },
                  ),
                  hintText: 'Search Destination',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(10.0),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Material(
                color: _isSearching ? Colors.red : Colors.indigo,
                borderRadius: BorderRadius.circular(4.0),
                child: IconButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_isSearching) {
                      _searchController.clear();
                      _placesResult.clear();
                      _markers.clear();
                      _isSearching = false;
                    } else {
                      _searchDestination(_searchController.text);
                      _isSearching = true;
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    _isSearching ? Icons.cancel_outlined : Icons.search,
                    color: Colors.white,
                    size: 30.0,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildPlacesResults() {
    return _placesResult.isNotEmpty
        ? Positioned(
            top: MediaQuery.of(context).size.height * 0.6,
            left: 20.0,
            right: 20.0,
            bottom: 20.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListView.builder(
                itemCount: _placesResult.length,
                itemBuilder: (context, index) {
                  p.PlacesSearchResult place = _placesResult[index];
                  LatLng destination = LatLng(place.geometry!.location.lat,
                      place.geometry!.location.lng);
                  return Card(
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Marker marker = Marker(
                          markerId: MarkerId(place.placeId),
                          position: destination,
                          infoWindow: InfoWindow(title: place.name),
                        );
                        setState(() {
                          _markers.clear();
                          _markers.add(marker);
                          _controller!
                              .moveCamera(CameraUpdate.newLatLng(destination));
                        });
                      },
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.navigation,
                          color: Colors.indigo,
                        ),
                        onPressed: () async {
                          await drawRoute(destination, context);
                          _isSearching = false;
                          _startNavigation();
                          _placesResult = [];
                          setState(() {});
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          )
        : Container();
  }

  Widget buildGoogleMap() {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Stack(children: [
        CustomGoogleMap(
          markers: _markers,
          polylines: _polylines,
          initialPosition:
              LatLng(_locationData.latitude!, _locationData.longitude!),
          onMapCreated: (controller) {
            _controller = controller;
          },
          onCameraMoveStarted: () {
            setState(() {
              _isStickyButtonPressed = false;
            });
          },
        ),
        _isUsingNavi
            ? Positioned(
                right: 10,
                top: 10,
                child: Text(
                  '${_locationData.speed?.toStringAsFixed(2)} m/s',
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ))
            : Container(),
        Positioned(
          left: 20,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: _isStickyButtonPressed ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: IconButton(
              onPressed: () {
                _isStickyButtonPressed = !_isStickyButtonPressed;
                _moveCameraToCurrentLocation();
                setState(() {});
              },
              icon: Icon(Icons.my_location,
                  color: _isStickyButtonPressed ? Colors.white : Colors.black),
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> drawRoute(LatLng destination, BuildContext context) async {
    List<LatLng> routePoints = [];
    try {
      navigationData = await _apiService.getNavigationPathNoLogin(
          _locationData.longitude!,
          _locationData.latitude!,
          destination.longitude,
          destination.latitude);

      routePoints = navigationData!.pathPointsToLatLng();
    } catch (e) {
      debugPrint(e.toString());
      Assets().showErrorSnackBar(context, e.toString());
    }
    Polyline route = await _mapService.drawRoute(routePoints);

    setState(() {
      _polylines.add(route);
    });
  }

  Future<List<LatLng>> searchPlaces(String value) async {
    _placesResult = await _searchService.searchPlaces(value);
    List<LatLng> destinations = _placesResult.map((place) {
      return LatLng(place.geometry!.location.lat, place.geometry!.location.lng);
    }).toList();
    return destinations;
  }

  Future<LatLng> searchPlace(String value) async {
    _placesResult = await _searchService.searchPlaces(value);
    p.PlacesSearchResult place = _placesResult.first;
    LatLng destination =
        LatLng(place.geometry!.location.lat, place.geometry!.location.lng);
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
    return destination;
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
