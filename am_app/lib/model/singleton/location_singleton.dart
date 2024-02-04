import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationSingleton {
  static final LocationSingleton _singleton = LocationSingleton._internal();

  factory LocationSingleton() {
    return _singleton;
  }
  Location location = Location();
  LocationData? _currentLocation;

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
}
