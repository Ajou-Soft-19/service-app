import 'dart:async';
import 'dart:math';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:am_app/screen/map/search_field.dart';
import 'package:am_app/screen/map/socket_service.dart';
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
  final _searchService = SearchService();
  final _apiService = ApiService();
  final _mapService = MapService();
  bool _serviceEnabled = false;
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  l.LocationData _locationData =
      l.LocationData.fromMap({'latitude': 37.1234, 'longitude': 127.1234});
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  List<p.PlacesSearchResult> _placesResult = [];
  StreamSubscription<l.LocationData>? _locationSubscription;
  NavigationData? navigationData;
  bool _isUsingNavi = false;
  double _currentHeading = 0.0;

  final socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _getLocation();
    _initSocketListener();
    FlutterCompass.events?.listen((CompassEvent event) {
      _currentHeading = event.heading!;
    });
  }

  void _initSocketListener() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await socketService.initSocket(userProvider, vehicleProvider);
    vehicleProvider.addListener(() {
      socketService.initSocket(userProvider, vehicleProvider);
    });
    socketService.startSendingLocationData(_location);
  }

  @override
  void dispose() {
    socketService.close();
    super.dispose();
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
    socketService.setUsingNavi(true);
    _locationSubscription =
        _location.onLocationChanged.listen((l.LocationData currentLocation) {
      setState(() async {
        _locationData = currentLocation;
        _updateUserMarker();
        _moveCameraToCurrentLocation();
        // _markers.add(AlertSingleton().checkAndCreateMarker()!);
        Marker? newMarker = AlertSingleton().checkAndCreateMarker();
        if (newMarker != null) {
          _markers.add(newMarker);
          LatLng currentPathPointLatLng =
              AlertSingleton().pathPoints![AlertSingleton().currentPathPoint!]!;
          List<LatLng> emergencyPathList = AlertSingleton().pathPoints!.values.toList();
          // LatLng nextPathPointLatLng =
          AlertSingleton().pathPoints![AlertSingleton().currentPathPoint!+2]!;
          Polyline newRoute = await _mapService.drawRouteRed(emergencyPathList);
          _polylines.add(newRoute);
          LatLng myLatLng = LocationSingleton().currentLocLatLng;
          String direction = AlertSingleton().determineDirection(
              AlertSingleton()
                      .calculateBearing(myLatLng, currentPathPointLatLng) -
                  _currentHeading);
          debugPrint("$direction");
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
          Assets().showSnackBar(context, '$direction 방향에서 긴급 차량 접근중');
          showDialog(
            barrierColor: Colors.transparent,
            context: context,
            builder: (BuildContext context) {
              Future.delayed(Duration(seconds: 1), () {
                Navigator.of(context).pop(true);
              });
              return Stack(
                children: <Widget>[
                  const SizedBox(),
                  Align(
                    alignment: alignment,
                    child: const Icon(
                      Icons.warning,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            },
          );
        }
      });
      // TODO: Send location data to the server
    });
  }

  void _stopNavigation() {
    _isUsingNavi = false;
    socketService.setUsingNavi(false);
    _locationSubscription?.cancel();
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
        ),
        body: Column(
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: SearchField(
                    onSubmitted: (value) async {
                      _placesResult = await _searchService.searchPlaces(value);
                      setState(() {});
                    },
                    label: '도착지',
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
              ],
            ),
            _placesResult.isNotEmpty
                ? Expanded(flex: 1,
                    child: ListView.builder(
                      itemCount: _placesResult.length,
                      itemBuilder: (context, index) {
                        p.PlacesSearchResult place = _placesResult[index];
                        LatLng destination = LatLng(
                            place.geometry!.location.lat,
                            place.geometry!.location.lng);
                        return ListTile(
                          title: Text(place.name),
                          onTap: () {
                            Marker marker = Marker(
                              markerId: MarkerId(place.placeId),
                              position: destination,
                              infoWindow: InfoWindow(title: place.name),
                            );
                            setState(() {
                              _markers.clear();
                              _markers.add(marker);
                              _controller!.moveCamera(
                                  CameraUpdate.newLatLng(destination));
                            });
                          },
                          trailing: IconButton(
                            icon: Icon(Icons.check_circle),
                            onPressed: () async {
                              await drawRoute(destination, context);
                              // 검색 결과를 비우고 UI를 업데이트합니다.
                              _placesResult = [];
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  )
                : Container(),
            Flexible(
              flex: 3,
              child: Stack(children: [
                CustomGoogleMap(
                  markers: _markers,
                  polylines: _polylines,
                  initialPosition:
                      LatLng(_locationData.latitude!, _locationData.longitude!),
                  onMapCreated: (controller) {
                    _controller = controller;
                  },
                ),
                _isUsingNavi ? Positioned(
                  right: 10,
                  top: 10,
                  child: Text(
                    '${_locationData.speed?.toStringAsFixed(2)} m/s',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ) : Container(),
                Positioned(
                  left: 20,
                  bottom:70,
                  child: IconButton(
                      onPressed: _moveCameraToCurrentLocation,
                      icon: const Icon(Icons.my_location)),
                )
              ]),
            ),
          ],
        ));
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
