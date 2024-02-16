import 'dart:io';
import 'dart:math';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/navigation_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/map/custom_google_map.dart';
import 'package:am_app/screen/map/map_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class NavigationRouteConfirmPage extends StatefulWidget {
  final LatLng source;
  final LatLng destination;
  final String destinationName;
  final bool hasEmergencyEventRegisterAuth;
  final bool isWaitingForEmergency;

  const NavigationRouteConfirmPage(
      {Key? key,
      required this.source,
      required this.destination,
      required this.destinationName,
      required this.hasEmergencyEventRegisterAuth,
      required this.isWaitingForEmergency})
      : super(key: key);

  @override
  State<NavigationRouteConfirmPage> createState() =>
      NavigationRouteConfirmPageState();
}

class NavigationRouteConfirmPageState
    extends State<NavigationRouteConfirmPage> {
  GoogleMapController? _controller;
  final _apiService = ApiService();
  final _mapService = MapService();

  NavigationData? navigationData;
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  bool _isSearchCompleted = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    super.dispose();
    _polylines.clear();
    _markers.clear();
  }

  void _initialize() async {
    searchAndDrawRoute(widget.destination, context);
  }

  Future<void> searchAndDrawRoute(
      LatLng destination, BuildContext context) async {
    List<LatLng> routePoints = [];
    try {
      if (widget.hasEmergencyEventRegisterAuth &&
          widget.isWaitingForEmergency) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final VehicleProvider vehicleProvider =
            Provider.of<VehicleProvider>(context, listen: false);
        navigationData = await _apiService.getNavigationPathLogin(
            widget.source.longitude,
            widget.source.latitude,
            destination.longitude,
            destination.latitude,
            userProvider,
            vehicleProvider);
      } else {
        navigationData = await _apiService.getNavigationPathNoLogin(
            widget.source.longitude,
            widget.source.latitude,
            destination.longitude,
            destination.latitude);
      }

      routePoints = navigationData!.pathPointsToLatLng();
    } catch (e) {
      debugPrint(e.toString());
      Assets().showErrorSnackBar(context, e.toString());
    }
    Polyline route = await _mapService.drawRoute(routePoints, id: 'pre_route');

    setState(() {
      _polylines.add(route);
      _isSearchCompleted = true;
    });
  }

  LatLngBounds _calculateBounds(LatLng source, LatLng destination) {
    double minLat = min(source.latitude, destination.latitude);
    double maxLat = max(source.latitude, destination.latitude);
    double minLong = min(source.longitude, destination.longitude);
    double maxLong = max(source.longitude, destination.longitude);

    return LatLngBounds(
      southwest: LatLng(minLat, minLong),
      northeast: LatLng(maxLat, maxLong),
    );
  }

  void _moveCameraToCoverBounds(LatLngBounds bounds) async {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double aspectRatio = screenWidth / screenHeight;
    double padding;

    if (aspectRatio > 1) {
      padding = screenHeight * 0.30;
    } else {
      padding = screenWidth * 0.30;
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, padding);
    await _controller!.animateCamera(cameraUpdate);
  }

  void _addMarkers(LatLng source, LatLng destination) {
    _markers.add(Marker(
      markerId: const MarkerId('pre_source'),
      position: source,
      infoWindow: const InfoWindow(title: 'Start Point'),
    ));

    _markers.add(Marker(
      markerId: const MarkerId('pre_destination'),
      position: destination,
      infoWindow: const InfoWindow(title: 'Destination Point'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));

    setState(() {});
  }

  void _returnData({bool returnNavigationData = false}) {
    if (returnNavigationData == true && navigationData != null) {
      Navigator.pop(context, navigationData);
    } else {
      Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          buildGoogleMap(),
          buildLocationRows(),
          _isSearchCompleted && _isMapReady
              ? buildNavigationInfo(navigationData!)
              : const Center(child: CircularProgressIndicator()),
          buildButtons(),
        ],
      ),
    );
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
              LatLng(widget.source.latitude, widget.source.longitude),
          onMapCreated: (controller) {
            _controller = controller;
            _moveCameraToCoverBounds(
                _calculateBounds(widget.source, widget.destination));
            _addMarkers(widget.source, widget.destination);
            setState(() {
              _isMapReady = true;
            });
          },
          onCameraMoveStarted: () {},
        ),
      ]),
    );
  }

  Widget buildLocationRows() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.8;

    if (screenWidth > 600) {
      containerWidth = 400;
    }

    return Positioned(
      top: MediaQuery.of(context).size.height * 0.05,
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: _buildLocationRow('Source:  ', 'My Location'),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: _buildLocationRow(
                  'Destination:   ', widget.destinationName,
                  isDestination: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(String label, String value,
      {bool isDestination = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: isDestination ? Colors.blue : Colors.black54,
              fontSize: isDestination ? 18.0 : 16.0,
              fontWeight: isDestination ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
      containerWidth = 400;
    }

    return Positioned(
      left: (screenWidth - containerWidth) / 2,
      right: (screenWidth - containerWidth) / 2,
      bottom: 50,
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.timer, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      'ETA',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$remainingTimeDisplay  ',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.directions, color: Colors.blue),
                    SizedBox(width: 10),
                    Text(
                      'Distance',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$remainingDistanceDisplay  ',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButtons() {
    double screenWidth = MediaQuery.of(context).size.width;
    double containerWidth = screenWidth * 0.80;

    if (screenWidth > 600) {
      containerWidth = 400;
    }

    return Positioned(
      left: (screenWidth - containerWidth) / 2,
      right: (screenWidth - containerWidth) / 2,
      bottom: 10,
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: TextButton.icon(
              key: const Key('cancel_route_button'),
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text(
                'Cancel',
                style: TextStyle(fontSize: 14),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.grey,
              ),
              onPressed: () {
                _returnData();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: TextButton.icon(
              key: const Key('start_navigation_button'),
              icon: const Icon(Icons.navigation, color: Colors.white),
              label: const Text(
                'Start',
                style: TextStyle(fontSize: 16),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                _returnData(returnNavigationData: true);
              },
            ),
          ),
        ],
      ),
    );
  }
}
