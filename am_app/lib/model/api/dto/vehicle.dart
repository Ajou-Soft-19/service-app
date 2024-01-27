class Vehicle {
  final int vehicleId;
  final String licenseNumber;
  final String vehicleType;
  final bool isEmergency;

  Vehicle(
      {required this.vehicleId,
      required this.licenseNumber,
      required this.vehicleType,
      this.isEmergency = false});

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vehicleId: json['vehicleId'],
      licenseNumber: json['licenceNumber'],
      vehicleType: "vehicleType",
      isEmergency: false,
    );
  }
}
