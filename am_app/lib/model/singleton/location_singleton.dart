import 'package:location/location.dart';

class LocationSingleton {
  static final LocationSingleton _singleton = LocationSingleton._internal();

  factory LocationSingleton() {
    return _singleton;
  }

  LocationSingleton._internal();

  LocationData? _currentLocation;

  LocationData? get currentLocation => _currentLocation;

  Future<LocationData?> getCurrentLocation() async {
    Location location = new Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    // _serviceEnabled = await location.serviceEnabled();
    // if (!_serviceEnabled) {
    //   _serviceEnabled = await location.requestService();
    //   if (!_serviceEnabled) {
    //     return null;
    //   }
    // }
    //
    // _permissionGranted = await location.hasPermission();
    // if (_permissionGranted == PermissionStatus.denied) {
    //   _permissionGranted = await location.requestPermission();
    //   if (_permissionGranted != PermissionStatus.granted) {
    //     return null;
    //   }
    // }

    print("Hello");

    _locationData = await location.getLocation();
    _currentLocation = _locationData;
    return _locationData;
  }
  void setLocationData(LocationData location){
    _currentLocation = location;
  }
}
