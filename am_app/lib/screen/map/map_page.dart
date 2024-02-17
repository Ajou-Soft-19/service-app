import 'dart:async';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/navigation_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/model/singleton/alert_singleton.dart';
import 'package:am_app/model/singleton/location_singleton.dart';

import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:am_app/model/socket/socket_connector.dart';
import 'package:am_app/screen/login/setting_page.dart';
import 'package:am_app/screen/map/navigation_route_confirm_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as l;
import 'package:google_maps_webservice/places.dart' as p;
import 'package:provider/provider.dart';
import 'package:smooth_compass/utils/smooth_compass.dart';
import 'package:smooth_compass/utils/src/compass_ui.dart';
import 'custom_google_map.dart';
import 'search_service.dart';
import 'map_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _controller;

  final l.Location _location = l.Location();
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  l.LocationData _locationData =
      l.LocationData.fromMap({'latitude': 37.1234, 'longitude': 127.1234});
  late Stream<CompassModel> compassStream;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _locationSingletonSubscription;

  final _searchService = SearchService();
  final _mapService = MapService();
  final _apiService = ApiService();
  final socketService = SocketConnector();
  int updateSync = 0;

  bool _isLoaded = false;
  DateTime? lastPressed;
  bool _serviceEnabled = false;
  bool _isUsingNavi = false;
  bool _isSearching = false;
  bool _isStickyButtonPressed = true;

  final TextEditingController _searchController = TextEditingController();
  NavigationData? navigationData;
  double _gpsHeading = 0.0;
  double _compassHeading = 0.0;
  double _currentHeading = 0.0;
  var lastUpdatedTime = '';

  List<p.PlacesSearchResult> _placesResult = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  String? _selectedPlaceName;

  bool hasEmergencyEventRegisterAuth = false;
  bool isWaitingForEmergency = false;
  int? emergencyEventId;

  @override
  void initState() {
    super.initState();
    initListeners();
  }

  @override
  void dispose() {
    socketService.close();
    _locationSubscription?.cancel();
    _locationSingletonSubscription?.cancel();
    _endNavigation();
    super.dispose();
  }

  void initListeners() async {
    await _getLocation();
    _initSocketListener();
    //_initCompassListener();
    await attachLocationUpdater();
    await attachUserMarkerChanger();
    await _initVehicleDataListener();
    initEmergencyVariables();
    setState(() {
      _isLoaded = true;
    });
  }

  void initEmergencyVariables() {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    vehicleProvider.addListener(() {
      setEmergencyVariables(userProvider, vehicleProvider);
    });
    setEmergencyVariables(userProvider, vehicleProvider);
  }

  void setEmergencyVariables(
      UserProvider userProvider, VehicleProvider vehicleProvider) {
    if (userProvider.hasEmergencyRole() && vehicleProvider.vehicleId != null) {
      setState(() {
        hasEmergencyEventRegisterAuth = true;
        isWaitingForEmergency = true;
      });
    } else {
      setState(() {
        hasEmergencyEventRegisterAuth = false;
        isWaitingForEmergency = false;
      });
    }
  }

  Future<void> _initSocketListener() async {
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await socketService.initSocket(userProvider, vehicleProvider.vehicleId);
    vehicleProvider.addListener(() {
      socketService.initSocket(userProvider, vehicleProvider.vehicleId);
    });
  }

  Future<void> _initCompassListener() async {
    compassStream = Compass().compassUpdates(
        interval: const Duration(milliseconds: 100),
        azimuthFix: 0,
        currentLoc: MyLoc(
            latitude: _locationData.latitude!,
            longitude: _locationData.longitude!));

    compassStream.listen((CompassModel compassModel) {
      _compassHeading = compassModel.angle - 8.0;
      if (_isStickyButtonPressed == false) {
        _currentHeading = _compassHeading;
      }
      _updateUserMarker();
    });
  }

  Future<void> attachLocationUpdater() async {
    _locationSubscription =
        _location.onLocationChanged.listen((l.LocationData currentLocation) {
      setState(() {
        _gpsHeading = currentLocation.heading ?? 0;
        // if (_gpsHeading != 0 &&
        //     (currentLocation.headingAccuracy ?? 0) <= 15 &&
        //     currentLocation.speed! >= 1.0) {
        //   _currentHeading = _gpsHeading;
        // } else {
        //   _currentHeading = _compassHeading;
        // }

        if (currentLocation.speed! * 3.6 >= 2) {
          _currentHeading = _gpsHeading;
        }
        _locationData = currentLocation;
      });

      socketService.setDirection(_currentHeading);
      socketService.sendLocationData(
          currentLocation, navigationData?.naviPathId, emergencyEventId);
    });
    return Future(() => null);
  }

  Future<void> attachUserMarkerChanger() {
    _locationSingletonSubscription = LocationSingleton()
        .locationStream
        .listen((LocationSingleton locationSingleton) {
      _updateUserMarker();
      _moveCameraToCurrentLocation();
      DateTime now = DateTime.now();
      lastUpdatedTime =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    });

    return Future(() => null);
  }

  Future<void> _getLocation() async {
    await _location.changeSettings(
        accuracy: l.LocationAccuracy.high, interval: 1000);
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

  void _updateUserMarker() async {
    BitmapDescriptor customIcon =
        await getBitmapDescriptorFromAssetBytes('assets/navigation.png', 110);

    Marker userMarker = Marker(
      markerId: const MarkerId('user'),
      position: LatLng(LocationSingleton().lat, LocationSingleton().lng),
      icon: customIcon,
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'user');
      _markers.add(userMarker);
    });
  }

  void _moveCameraToCurrentLocation() async {
    if (_isStickyButtonPressed == false || _isSearching) return;

    LatLng userLocation = LocationSingleton().getCurrentLocLatLng() ??
        LatLng(_locationData.latitude!, _locationData.longitude!);
    var bearing = LocationSingleton().direction;

    var newLatLng = _mapService.calculateCameraPosition(
        userLocation.latitude, userLocation.longitude, bearing);

    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
            target: newLatLng, zoom: 18.0, bearing: bearing, tilt: 50.0),
      ),
    );
  }

  Future<void> _initVehicleDataListener() async {
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
        if (currentPathPointLatLng == null) return;
        LatLng myLatLng = LocationSingleton().getCurrentLocLatLng() ??
            LatLng(_locationData.latitude!, _locationData.longitude!);
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
    bool isNaviConfirmed = await confirmNavigationData(destination, context);
    if (isNaviConfirmed == false) return;
    setState(() {
      _isSearching = false;
      _isStickyButtonPressed = true;
      _isUsingNavi = true;
      _placesResult = [];
    });
    _moveCameraToCurrentLocation();
    socketService.setUsingNavi(true);
    Assets().showSnackBar(context, 'Navigation started.');
  }

  void _endNavigation() {
    if (navigationData == null) return;
    _isUsingNavi = false;
    socketService.setUsingNavi(false);
    _markers.clear();
    _polylines.clear();
    _searchController.clear();
    navigationData = null;
    if (emergencyEventId != null) {
      _apiService.endEmergencyEvent(
          emergencyEventId!, Provider.of<UserProvider>(context, listen: false));
      emergencyEventId = null;
    }
    setState(() {});
    Assets().showSnackBar(context, 'Navigation ended.');
  }

  void _searchDestination(String value) async {
    LatLng destination;
    try {
      destination = await searchPlace(value);
    } catch (e) {
      debugPrint(e.toString());
      Assets().showErrorSnackBar(context, 'Failed to search destination.');
      _isSearching = false;
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

        if (_isSearching) {
          _searchController.clear();
          _placesResult.clear();
          _markers.clear();
          _isSearching = false;
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
            hasEmergencyEventRegisterAuth && !_isSearching
                ? buildSirenButton()
                : Container(),
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
      top: MediaQuery.of(context).size.height * 0.035,
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
                  _isStickyButtonPressed = false;
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
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (_isSearching) {
                      _searchController.clear();
                      _placesResult.clear();
                      _markers.clear();
                      _isSearching = false;
                    } else {
                      _searchDestination(_searchController.text);
                      _isSearching = true;
                      _isStickyButtonPressed = false;
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
        ? DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.6,
            builder: (BuildContext context, ScrollController scrollController) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: containerWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.drag_handle),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: _placesResult.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.01),
                            child: Divider(
                              color: Colors.grey[300],
                              height: 1,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            p.PlacesSearchResult place = _placesResult[index];
                            LatLng destination = LatLng(
                                place.geometry!.location.lat,
                                place.geometry!.location.lng);
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
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
                                  _controller!.moveCamera(
                                      CameraUpdate.newLatLng(destination));
                                });
                              },
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.navigation,
                                  color: Colors.indigo,
                                  size: 30,
                                ),
                                onPressed: () async {
                                  _selectedPlaceName = place.name;
                                  _startNavigation(destination);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          onCameraMoveStarted: (event) {
            print(event);
          },
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.04,
          top: MediaQuery.of(context).size.height * 0.2,
          child: Text(
            '${((_locationData.speed ?? 0) * 3.6).toInt()} km/h',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.04,
          top: MediaQuery.of(context).size.height * 0.3,
          child: Text(
            LocationSingleton().confidence != null
                ? '${(LocationSingleton().confidence! * 100).toInt()} %'
                : 'null %',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.04,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Text(
            '${(_currentHeading).toInt()} °',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width * 0.04,
          top: MediaQuery.of(context).size.height * 0.5,
          child: Text(
            lastUpdatedTime,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        !_isSearching
            ? Positioned(
                top: _isUsingNavi ? 20 : null,
                left: 20,
                bottom: _isUsingNavi ? null : 20,
                child: FloatingActionButton(
                    heroTag: 'stickyButton',
                    onPressed: () {
                      _isStickyButtonPressed = !_isStickyButtonPressed;
                      _moveCameraToCurrentLocation();
                      setState(() {});
                    },
                    backgroundColor:
                        _isStickyButtonPressed ? Colors.blue : Colors.white,
                    child: Icon(Icons.my_location,
                        color: _isStickyButtonPressed
                            ? Colors.white
                            : Colors.black)),
              )
            : Container(),
      ]),
    );
  }

  void showEndNavigationConfirm() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.95;

    if (screenWidth > 600) {
      containerWidth = 500;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Container(
                width: containerWidth,
                margin: const EdgeInsets.all(10),
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Stop Navigation',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Are you sure you want to stop navigation?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _endNavigation();
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
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

    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.80;

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
                          LocationSingleton().locationName == ''
                              ? _selectedPlaceName ?? 'Destination'
                              : LocationSingleton().locationName,
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.timer, color: Colors.green),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        remainingTimeDisplay,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Icon(Icons.drive_eta, color: Colors.blue),
                      const SizedBox(
                        width: 3,
                      ),
                      Text(
                        remainingDistanceDisplay,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSirenButton() {
    if (hasEmergencyEventRegisterAuth == false) {
      return const SizedBox.shrink();
    }

    IconData iconData;
    String text;
    Color color;

    if (isWaitingForEmergency && emergencyEventId != null) {
      iconData = FontAwesomeIcons.triangleExclamation;
      text = 'On Action';
      color = Colors.red;
    } else if (isWaitingForEmergency) {
      iconData = FontAwesomeIcons.car;
      text = 'Pending';
      color = Colors.red;
    } else {
      iconData = FontAwesomeIcons.powerOff;
      text = 'Off';
      color = Colors.white;
    }

    return Positioned(
      left: 20,
      bottom: _isUsingNavi ? null : MediaQuery.of(context).size.height * 0.12,
      top: _isUsingNavi ? MediaQuery.of(context).size.height * 0.12 : null,
      child: AnimatedContainer(
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton.extended(
          heroTag: 'sirenButton',
          onPressed: () {
            setState(() {
              if (navigationData != null) {
                Assets().showErrorSnackBar(context, 'End Navigation First');
                return;
              }
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    backgroundColor: Colors.white,
                    title: const Text(
                      'Confirm',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    content: Text(
                      isWaitingForEmergency
                          ? 'Do you want to turn off Emergency State?'
                          : 'Do you want to turn on Emergency State?',
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            isWaitingForEmergency = !isWaitingForEmergency;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            });
          },
          icon: Icon(
            iconData,
            color: isWaitingForEmergency ? Colors.white : Colors.black,
          ),
          label: Text(
            text,
            style: TextStyle(
              color: isWaitingForEmergency ? Colors.white : Colors.black,
            ),
          ),
          backgroundColor: color,
        ),
      ),
    );
  }

  Future<bool> confirmNavigationData(
      LatLng destination, BuildContext context) async {
    List<LatLng> routePoints = [];
    p.PlacesSearchResult? place = findPlaceByLatLng(destination);

    if (place == null) return false;
    try {
      navigationData = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NavigationRouteConfirmPage(
            source: LocationSingleton().getCurrentLocLatLng() ??
                LatLng(_locationData.latitude!, _locationData.longitude!),
            destination: destination,
            destinationName: place.name,
            hasEmergencyEventRegisterAuth: hasEmergencyEventRegisterAuth,
            isWaitingForEmergency: isWaitingForEmergency,
          ),
        ),
      );

      if (navigationData == null) return false;

      await registerEmergencyEvent(navigationData!.naviPathId);

      routePoints = navigationData!.pathPointsToLatLng();
    } catch (e) {
      debugPrint(e.toString());
      Assets().showErrorSnackBar(context, e.toString());
      return false;
    }

    Polyline route = await _mapService.drawRoute(routePoints,
        id: 'route_confirmed', width: 8);

    setState(() {
      _polylines.add(route);
    });

    return true;
  }

  Future<void> registerEmergencyEvent(int? navigationPahtId) async {
    if (hasEmergencyEventRegisterAuth == false ||
        isWaitingForEmergency == false) return Future(() => null);
    if (navigationPahtId == null) {
      throw Exception('Navigation Path Id is null');
    }
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int vehicleId = int.parse(vehicleProvider.vehicleId!);

    try {
      emergencyEventId = await _apiService.registerEmergencyEvent(
          vehicleId, navigationPahtId, userProvider);
    } catch (e) {
      throw Exception('Error occurred in registerEmergencyEvent: $e');
    }

    debugPrint('Emergency Event Id: $emergencyEventId');
    return Future(() => null);
  }

  p.PlacesSearchResult? findPlaceByLatLng(LatLng destination) {
    for (var place in _placesResult) {
      if (place.geometry!.location.lat == destination.latitude &&
          place.geometry!.location.lng == destination.longitude) {
        return place;
      }
    }
    return null;
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
}
