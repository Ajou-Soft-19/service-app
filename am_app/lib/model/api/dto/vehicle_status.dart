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
  // final String? navigationPathId;
  // final bool onAction;

  VehicleStatus({
    required this.vehicleStatusId,
    required this.longitude,
    required this.latitude,
    required this.lastUpdateTime,
    required this.meterPerSec,
    required this.direction,
    // this.navigationPathId,
    this.vehicleInfo,
    required this.emergencyVehicle,
    // required this.onAction,
  });

  factory VehicleStatus.fromJson(Map<String, dynamic> json) {
    return VehicleStatus(
      vehicleStatusId: json['vehicleStatusId'],
      longitude: json['longitude'],
      latitude: json['latitude'],
      lastUpdateTime: json['lastUpdateTime'],
      meterPerSec: json['meterPerSec'],
      direction: json['direction'],
      // navigationPathId: json['navigationPathId'],
      vehicleInfo: json['vehicleInfo'] != null
          ? Vehicle.fromJson(json['vehicleInfo'])
          : null,
      emergencyVehicle: json['emergencyVehicle'],
      // onAction: json['onAction'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VehicleStatus && other.vehicleStatusId == vehicleStatusId;
  }

  @override
  int get hashCode => vehicleStatusId.hashCode;
}
