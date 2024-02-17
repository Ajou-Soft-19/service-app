import 'dart:io';

import 'package:am_app/model/api/dto/vehicle.dart';
import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/asset/app_bar.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/vehicle/register_vehicle_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({Key? key}) : super(key: key);

  @override
  _VehicleListPageState createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  List<Vehicle>? vehicles = [];

  bool isLoading = true;
  bool getSucceed = false;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    loadVehicles(userProvider);
  }

  Future<void> loadVehicles(UserProvider userProvider) async {
    List<Vehicle>? newVehicles;
    try {
      newVehicles = await VehicleApi().getVehicleInfo(userProvider);
      getSucceed = true;
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
    } finally {
      setState(() {
        vehicles = newVehicles;
        isLoading = false;
      });
    }
  }

  Future<void> registerVehicle(UserProvider userProvider) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterVehiclePage()),
    );
    loadVehicles(userProvider);
  }

  Future<void> onSelect(
      Vehicle vehicle, VehicleProvider vehicleProvider) async {
    if (vehicleProvider.vehicleId != null &&
        vehicle.vehicleId == int.parse(vehicleProvider.vehicleId!)) {
      await vehicleProvider.deleteState();
      return;
    }

    vehicleProvider.setState(vehicle.vehicleId.toString(),
        vehicle.licenseNumber, vehicle.vehicleType, vehicle.isEmergency);

    Assets().showSnackBar(context, 'Vehicle Selected!');
  }

  Future<void> onDelete(Vehicle vehicle, VehicleProvider vehicleProvider,
      UserProvider userProvider) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Vehicle"),
          content: const Text("Are you sure you want to delete this vehicle?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Confirm", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  if (vehicleProvider.vehicleId != null &&
                      vehicle.vehicleId ==
                          int.parse(vehicleProvider.vehicleId!)) {
                    throw Exception(
                        'Cannot delete selected vehicle.\nUnselect the vehicle first.');
                  }

                  sleep(const Duration(milliseconds: 300));
                  await VehicleApi()
                      .deleteVehicle(vehicle.vehicleId, userProvider);

                  await loadVehicles(userProvider);
                } catch (e) {
                  Assets().showErrorSnackBar(context, e.toString());
                }

                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void onMoreVertPressed(Vehicle vehicle, VehicleProvider vehicleProvider,
      UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Assets()
                  .showErrorSnackBar(context, 'Edit is not implemented yet.');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              onDelete(vehicle, vehicleProvider, userProvider);
            },
          ),
        ],
      ),
    );
  }

  bool ifSelected(String? vehicleId, VehicleProvider vehicleProvider) {
    return vehicleProvider.vehicleId == vehicleId;
  }

  @override
  Widget build(BuildContext context) {
    final VehicleProvider vehicleProvider =
        Provider.of<VehicleProvider>(context);
    final UserProvider userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Vehicle List',
        backButton: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : getSucceed == false
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.error, color: Colors.red, size: 60),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Error: Failed to load vehicles'),
                      )
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView.builder(
                      itemCount: vehicles!.length + 1,
                      itemBuilder: (context, index) {
                        if (index < vehicles!.length) {
                          final vehicle = vehicles![index];
                          return Card(
                            color: ifSelected(vehicle.vehicleId.toString(),
                                    vehicleProvider)
                                ? Colors.blue.shade100
                                : Colors.white,
                            elevation: 5,
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: Icon(
                                  getIconBasedOnVehicleType(
                                      vehicle.vehicleType),
                                  color: Colors.blue,
                                  size: 40),
                              title: Text(vehicle.licenseNumber,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Vehicle ID: ${vehicle.vehicleId} | Type: ${vehicle.vehicleType}',
                                  style: const TextStyle(fontSize: 15)),
                              onTap: () => onSelect(vehicle, vehicleProvider),
                              trailing: IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => onMoreVertPressed(
                                    vehicle, vehicleProvider, userProvider),
                              ),
                            ),
                          );
                        } else {
                          return Card(
                            color: Colors.blue.shade50,
                            elevation: 5,
                            margin: const EdgeInsets.all(10),
                            child: ListTile(
                              leading: const Icon(Icons.add,
                                  color: Colors.blue, size: 40),
                              title: const Text('Register Vehicle',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                              onTap: () {
                                registerVehicle(userProvider);
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
    );
  }

  IconData getIconBasedOnVehicleType(String vehicleType) {
    switch (vehicleType) {
      case 'LIGHTWEIGHT_CAR':
      case 'SMALL_CAR':
      case 'MEDIUM_CAR':
      case 'LARGE_CAR':
        return Icons.directions_car;
      case 'LARGE_TRUCK':
      case 'SPECIAL_TRUCK':
        return Icons.local_shipping;
      case 'AMBULANCE':
        return Icons.local_hospital;
      case 'FIRE_TRUCK_MEDIUM':
      case 'FIRE_TRUCK_LARGE':
        return Icons.local_fire_department;
      default:
        return Icons.directions_car;
    }
  }
}
