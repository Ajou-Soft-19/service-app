import 'dart:io';

import 'package:am_app/model/api/dto/vehicle.dart';
import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
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
          title: const Text("차량 삭제"),
          content: const Text("정말로 이 차량을 삭제하시겠습니까?"),
          actions: <Widget>[
            TextButton(
              child: const Text("취소"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("삭제", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  if (vehicleProvider.vehicleId != null &&
                      vehicle.vehicleId ==
                          int.parse(vehicleProvider.vehicleId!)) {
                    throw Exception('현재 선택된 차량은 삭제할 수 없습니다.');
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
            title: const Text('수정'),
            onTap: () {
              Assets().showErrorSnackBar(context, '수정 기능은 아직 지원하지 않습니다.');
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('삭제'),
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
      appBar: AppBar(
        title: const Text('차량 조회'),
        backgroundColor: Colors.blue,
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
              : ListView.builder(
                  itemCount: vehicles!.length + 1,
                  itemBuilder: (context, index) {
                    if (index < vehicles!.length) {
                      final vehicle = vehicles![index];
                      return Card(
                        color: ifSelected(
                                vehicle.vehicleId.toString(), vehicleProvider)
                            ? Colors.blue.shade100
                            : Colors.white,
                        elevation: 5,
                        margin: const EdgeInsets.all(10),
                        child: ListTile(
                          leading: const Icon(Icons.directions_car,
                              color: Colors.blue, size: 40),
                          title: Text(vehicle.licenseNumber,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              'Vehicle ID: ${vehicle.vehicleId}', // 디버깅용 나중에 vehicleType으로 변경
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
                          title: const Text('차량 추가',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          onTap: () {
                            registerVehicle(userProvider);
                          },
                        ),
                      );
                    }
                  },
                ),
    );
  }
}
