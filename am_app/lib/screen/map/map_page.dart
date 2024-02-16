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
import 'package:flutter/services.dart';
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

  final _searchService = SearchService();
  final _apiService = ApiService();
  final _mapService = MapService();
  final socketService = SocketConnector();
  bool _isLoaded = false;
  DateTime? lastPressed;
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
    //await _initCompassListener();
    await attachUserMarkerChanger();
    await _initVehicleDataListener();
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
  }

  Future<void> _initCompassListener() {
    FlutterCompass.events?.listen((CompassEvent event) {
      _currentHeading = event.heading!;
      if (_currentHeading < 0) {
        _currentHeading += 360;
      }
      socketService.setDirection(_currentHeading);
    });

    return Future(() => null);
  }

  Future<void> attachUserMarkerChanger() {
    _location.changeSettings(
      accuracy: l.LocationAccuracy.high,
      interval: 1500,
    );
    _location.onLocationChanged.listen((l.LocationData currentLocation) {
      setState(() {
        if(isArrived()){Assets().showSnackBar(context, 'Almost arrived. End guidance'); debugPrint("Arrived"); _endNavigation(); return;}
        _currentHeading = currentLocation.heading ?? 0;
        if(_currentHeading!=0) socketService.setDirection(_currentHeading);
        _locationData = currentLocation;
        socketService.sendLocationData(currentLocation);
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

  Future<void> _initVehicleDataListener() async {
    AlertSingleton().onVehicleDataUpdated.listen((licenseNumber) {
      setState(() async {
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
        if(await _mapService.doPathsIntersect(navigationData!.pathPoint, latLngToPathPoints(AlertSingleton().pathPoints[licenseNumber]!.values.toList()))) {
          debugPrint("Hello");
          // 메시지 예쁘게 나오게 수정, 경로 겹쳤다고 할 때 미니맵을 띄울까?
        }

        LatLng? currentPathPointLatLng =
            AlertSingleton().markers[licenseNumber]?.position;
        if (currentPathPointLatLng == null) return;
        LatLng myLatLng = LocationSingleton().currentLocLatLng;
        String? direction = AlertSingleton().determineDirection(AlertSingleton()
                .calculateBearing(myLatLng, currentPathPointLatLng) -
            _currentHeading);
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
    return Future(() => null);
  }

  void _startNavigation(destination) async {
    await drawRoute(destination, context);
    setState(() {
      _isSearching = false;
      _isStickyButtonPressed = true;
      _isUsingNavi = true;
      _placesResult = [];
    });
    _moveCameraToCurrentLocation();
    socketService.setUsingNavi(true);
  }

  void _endNavigation() {
    _isUsingNavi = false;
    socketService.setUsingNavi(false);
    _markers.clear();
    _polylines.clear();
    _searchController.clear();
    navigationData = null;
    setState(() {});
  }

  void _updateUserMarker() async {
    BitmapDescriptor customIcon =
        await getBitmapDescriptorFromAssetBytes('assets/navigation.png', 110);

    Marker userMarker = Marker(
      markerId: const MarkerId('user'),
      position: LatLng(LocationSingleton().lat, LocationSingleton().lng),
      // position: LatLng(_locationData.latitude!, _locationData.longitude!),
      // The rotation is the direction of travel
      // rotation: _currentHeading / 180 * pi,
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
            bearing: LocationSingleton().direction,
            // bearing: _currentHeading,
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

// WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (!_isLoaded) {
  //     Assets().showLoadingDialog(context, "Loading...");
  //   } else if (_isLoaded && Navigator.of(context).canPop()) {
  //     Navigator.of(context).pop();
  //   }
  // });

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }

        if (_isUsingNavi) {
          showEndNavigationConfirm();
          return;
        }

        final now = DateTime.now();
        if (lastPressed == null ||
            now.difference(lastPressed!) > const Duration(seconds: 2)) {
          lastPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red.shade400,
              content: const Text(
                  'Are you sure you want to exit the app? Press the Back button once more to exit.'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            buildGoogleMap(),
            !_isUsingNavi ? buildSearchRow() : Container(),
            buildPlacesResults(),
            _isUsingNavi ? buildNavigationInfo(navigationData!) : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildSearchRow() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.9;

    if (screenWidth > 600) {
      containerWidth = 540;
    }

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.025,
      left: (screenWidth - containerWidth) / 2,
      right: (screenWidth - containerWidth) / 2,
      child: Container(
        width: containerWidth,
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
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.9;

    if (screenWidth > 600) {
      containerWidth = 540;
    }

    return _placesResult.isNotEmpty
        ? Positioned(
            top: MediaQuery.of(context).size.height * 0.6,
            left: (screenWidth - containerWidth) / 2,
            right: (screenWidth - containerWidth) / 2,
            bottom: 20.0,
            child: Container(
              width: containerWidth,
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
                          _startNavigation(destination);
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
          onCameraMoveStarted: () {},
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.04,
          top: MediaQuery.of(context).size.height * 0.2,
          child: Text(
            (_locationData.speed ?? 0 * 3.6).toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _isUsingNavi
            ? Positioned(
                left: 20,
                bottom: 90,
                child: FloatingActionButton(
                    onPressed: () {
                      showEndNavigationConfirm();
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.stop)),
              )
            : Container(),
        Positioned(
          left: 20,
          bottom: 20,
          child: FloatingActionButton(
              onPressed: () {
                _isStickyButtonPressed = !_isStickyButtonPressed;
                _moveCameraToCurrentLocation();
                setState(() {});
              },
              backgroundColor:
                  _isStickyButtonPressed ? Colors.blue : Colors.white,
              child: Icon(Icons.my_location,
                  color: _isStickyButtonPressed ? Colors.white : Colors.black)),
        ),
      ]),
    );
  }

  void showEndNavigationConfirm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Navigation'),
          content: const Text('Are you sure you want to stop navigation?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                _endNavigation();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildNavigationInfo(NavigationData navigationData) {
    double remainingDistanceKm = navigationData.distance / 1000;
    String remainingDistanceDisplay = remainingDistanceKm < 1
        ? '${(remainingDistanceKm * 1000).round()} m'
        : '${remainingDistanceKm.toStringAsFixed(0)} km';

    int remainingTimeMin = (navigationData.duration / 60).round();
    String remainingTimeDisplay = remainingTimeMin < 60
        ? '$remainingTimeMin M'
        : '${remainingTimeMin ~/ 60} H ${remainingTimeMin % 60} M';

    String currentLocation =
        LocationSingleton().locationName;
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.50;

    if (screenWidth > 600) {
      containerWidth = 300;
    }

    return Positioned(
      left: (screenWidth - containerWidth) / 2,
      right: (screenWidth - containerWidth) / 2,
      bottom: 0,
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(1),
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.location_on, color: Colors.red),
                      Flexible(
                        child: Text(
                          currentLocation,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Text(
                    remainingTimeDisplay,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    remainingDistanceDisplay,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  List<PathPoint> latLngToPathPoints(List<LatLng> latLngList) {
    return latLngList.asMap().entries.map((entry) {
      int index = entry.key;
      LatLng latLng = entry.value;
      return PathPoint(index: index, location: Location(longitude: latLng.longitude, latitude: latLng.latitude));
    }).toList();
  }

  bool isArrived(){
    bool arrived = false;
    if(navigationData == null) return false;
    if(AlertSingleton().calculateDistance(LocationSingleton().currentLocLatLng, navigationData!.pathPointsToLatLng().last)<50) {
      arrived = true;
    }
    return arrived;
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
