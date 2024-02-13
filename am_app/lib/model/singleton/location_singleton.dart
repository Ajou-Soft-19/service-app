import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationSingleton {
  static final LocationSingleton _singleton = LocationSingleton._internal();
  Location location = Location();
  LocationData? _currentLocation;
  double lat = 0.0;
  double lng = 0.0;
  double direction = 0.0;
  String locationName = '';

  factory LocationSingleton() {
    return _singleton;
  }

  LocationSingleton._internal(){
    location.onLocationChanged.listen((LocationData currentLocation){
      _currentLocation = currentLocation;
    });
  }

  LatLng get currentLocLatLng => LatLng(
    _currentLocation?.latitude ?? 0,
    _currentLocation?.longitude ?? 0,
  );
  LocationData? get currentLocation => _currentLocation;

  Future<LocationData?> getCurrentLocation() async {
    Location location = Location();
    LocationData _locationData;

    _locationData = await location.getLocation();
    _currentLocation = _locationData;
    return _locationData;
  }
  void setLocationData(LocationData location){
    _currentLocation = location;
  }

  void setMapMatchedLocation(Map<String, dynamic> parsedJson){
    Map<String, dynamic> data = parsedJson['data'];
    Map<String, dynamic> location = data['location'];
    lat = location['latitude'];
    lng = location['longitude'];
    direction = location['direction'];
    locationName = location['locationName'];
  }

}
