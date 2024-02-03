import 'package:am_app/model/api/dto/vehicle.dart';

class VehicleStatus {
  final String vehicleStatusId;
  final double longitude;
  final double latitude;
  final String lastUpdateTime;
  final double meterPerSec;
  final double direction;
  final Vehicle? vehicleInfo;
  final bool emergencyVehicle;
  final int emergencyEventId;

  VehicleStatus({
    required this.vehicleStatusId,
    required this.longitude,
    required this.latitude,
    required this.lastUpdateTime,
    required this.meterPerSec,
    required this.direction,
    this.vehicleInfo,
    required this.emergencyVehicle,
    required this.emergencyEventId,
  });

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      vehicleStatusId: json['vehicleStatusId'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      lastUpdateTime: json['lastUpdateTime'],
      meterPerSec: json['meterPerSec'],
      direction: json['direction'],
      vehicleInfo: json['vehicleInfo'] != null
          ? Vehicle.fromJson(json['vehicleInfo'])
          : null,
      emergencyVehicle: json['emergencyVehicle'],
      emergencyEventId: json['emergencyEventId'] ?? -1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VehicleStatus && other.vehicleStatusId == vehicleStatusId;
  }

  @override
  int get hashCode => vehicleStatusId.hashCode;

  @override
  String toString() {
    return 'VehicleStatus(vehicleStatusId: $vehicleStatusId, longitude: $longitude, latitude: $latitude, lastUpdateTime: $lastUpdateTime, meterPerSec: $meterPerSec, direction: $direction, vehicleInfo: $vehicleInfo, emergencyVehicle: $emergencyVehicle, emergencyEventId: $emergencyEventId)';
  }
}
