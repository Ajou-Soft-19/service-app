import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VehicleProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoaded = false;
  String? _vehicleId;
  String? _licenseNumber;
  String? _carType;
  bool? _isEmergency;

  bool get isLoading => isLoaded;
  String? get vehicleId => _vehicleId;
  String? get licenseNumber => _licenseNumber;
  String? get carType => _carType;
  bool? get isEmergency => _isEmergency;

  Future<void> setState(String vehicleId, String licenseNumber, String carType,
      bool isEmergency) async {
    _vehicleId = vehicleId;
    _licenseNumber = licenseNumber;
    _carType = carType;
    _isEmergency = isEmergency;
    await _storage.write(key: 'vehicleId', value: vehicleId);
    await _storage.write(key: 'licenseNumber', value: licenseNumber);
    await _storage.write(key: 'carType', value: carType);
    await _storage.write(
        key: 'isEmergency', value: isEmergency ? 'true' : 'false');
    notifyListeners();
  }

  Future<void> updateState(String? vehicleId, String? licenseNumber,
      String? carType, bool? isEmergency) async {
    if (vehicleId != null) {
      _vehicleId = vehicleId;
      await _storage.write(key: 'vehicleId', value: vehicleId);
    }

    if (licenseNumber != null) {
      _licenseNumber = licenseNumber;
      await _storage.write(key: 'licenseNumber', value: licenseNumber);
    }

    if (carType != null) {
      _carType = carType;
      await _storage.write(key: 'carType', value: carType);
    }

    if (isEmergency != null) {
      _isEmergency = isEmergency;
      await _storage.write(
          key: 'isEmergency', value: isEmergency ? 'true' : 'false');
    }

    notifyListeners();
  }

  Future<void> deleteState() async {
    _vehicleId = null;
    _licenseNumber = null;
    _carType = null;
    _isEmergency = null;
    await _storage.delete(key: 'vehicleId');
    await _storage.delete(key: 'licenseNumber');
    await _storage.delete(key: 'carType');
    await _storage.delete(key: 'isEmergency');
    notifyListeners();
  }

  Future<void> initState() async {
    _vehicleId = await _storage.read(key: 'vehicleId');
    _licenseNumber = await _storage.read(key: 'licenseNumber');
    _carType = await _storage.read(key: 'carType');
    _isEmergency = (await _storage.read(key: 'isEmergency')) == 'true';
    isLoaded = true;
    notifyListeners();
  }
}
