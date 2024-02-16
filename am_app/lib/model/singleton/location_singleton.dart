import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSingleton {
  static final LocationSingleton _singleton = LocationSingleton._internal();
  double lat = 0.0;
  double lng = 0.0;
  double direction = 0.0;
  String locationName = '';
  double? confidence = 0.0;
  final _locationController = StreamController<LocationSingleton>.broadcast();
  Stream<LocationSingleton> get locationStream => _locationController.stream;

  factory LocationSingleton() {
    return _singleton;
  }

  LocationSingleton._internal();

  LatLng? getCurrentLocLatLng() {
    if(lat == 0.0 && lng == 0.0) return null;

    return LatLng(
      lat,
      lng,
    );
  }

  void setMapMatchedLocation(Map<String, dynamic> parsedJson) {
    Map<String, dynamic> data = parsedJson['data'];
    if (data['vehicleStatusId'] != null) return;
    if (data['location'] == null) return;
    Map<String, dynamic> location = data['location'];
    lat = location['latitude'];
    lng = location['longitude'];
    direction = location['direction'];
    locationName = location['locationName'];
    confidence = location['confidence'];
    _locationController.add(this);
  }
}
