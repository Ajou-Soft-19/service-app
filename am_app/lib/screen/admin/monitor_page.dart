import 'dart:math';

import 'package:am_app/model/api/dto/vehicle.dart';
import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage>
    with AutomaticKeepAliveClientMixin<AdminPage> {
  GoogleMapController? _controller;

  // 차량 정보를 담을 리스트
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;
  bool _getSucceed = false;
  bool _showVehicleList = false;
  Vehicle? selectedVehicle;

  // 구글맵에 표시할 마커 및 원을 담을 리스트
  Set<Circle> _circles = <Circle>{};
  Set<Marker> _markers = <Marker>{};

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _addCircle(const LatLng(37.5665, 126.9780));
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    List<Vehicle>? newVehicles;
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      newVehicles = await VehicleApi().getVehicleInfo(userProvider);
      _getSucceed = true;
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
    } finally {
      setState(() {
        _vehicles = newVehicles!;
        _isLoading = false;
      });
    }
  }

  void _addCircle(LatLng position) {
    final circleId = 'circle_${_circles.length}';

    setState(() {
      _circles.add(
        Circle(
          circleId: CircleId(circleId),
          center: position,
          radius: 1000, // 원의 반지름을 설정합니다. 단위는 미터입니다.
          fillColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 1,
          strokeColor: Colors.blue,
        ),
      );
    });
  }

  Future<void> _createMarkers(
      List<Marker> normalVehicles, List<Marker> emergencyVehicles) async {
    final BitmapDescriptor normalVehicleIcon =
        await getBitmapDescriptorFromAssetBytes('assets/circle.png', 110);
    final BitmapDescriptor emergencyVehicleIcon =
        await getBitmapDescriptorFromAssetBytes('assets/circle2.png', 110);

    for (var vehicle in normalVehicles) {
      Marker normalVehicleMarker = Marker(
        markerId: MarkerId('normalVehicle_${vehicle.markerId.value}'),
        position: vehicle.position,
        icon: normalVehicleIcon,
      );
      _markers.add(normalVehicleMarker);
    }

    for (var vehicle in emergencyVehicles) {
      Marker emergencyVehicleMarker = Marker(
        markerId: MarkerId('emergencyVehicle_${vehicle.markerId.value}'),
        position: vehicle.position,
        icon: emergencyVehicleIcon,
      );
      _markers.add(emergencyVehicleMarker);
    }

    setState(() {});
  }

  void _randomizeMarkersAndCircles() {
    final random = Random();

    setState(() {
      _markers = _markers.map((marker) {
        return Marker(
          markerId: marker.markerId,
          position: LatLng(
            37.5665 + random.nextDouble() * 0.01,
            126.9780 + random.nextDouble() * 0.01,
          ),
        );
      }).toSet();

      _circles = _circles.map((circle) {
        return Circle(
          circleId: circle.circleId,
          center: LatLng(
            37.5665 + random.nextDouble() * 0.01,
            126.9780 + random.nextDouble() * 0.01,
          ),
          radius: 1000,
          fillColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 1,
          strokeColor: Colors.blue,
        );
      }).toSet();
    });
  }

  bool ifSelected(String? vehicleId) {
    if (selectedVehicle == null) return false;
    return selectedVehicle!.vehicleId.toString() == vehicleId;
  }

  onSelect(Vehicle? vehicle) {
    setState(() {
      selectedVehicle = vehicle;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Monitoring'),
        actions: [
          IconButton(
            icon: Icon(_showVehicleList ? Icons.map : Icons.list),
            onPressed: () async {
              await _loadVehicles();
              setState(() {
                _showVehicleList = !_showVehicleList;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.5665, 126.9780), // 초기 위치를 서울로 설정합니다.
              zoom: 11.0,
            ),
            markers: _markers,
            circles: _circles,
          ),
          if (_showVehicleList)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.2, // 화면의 20% 크기로 설정합니다.
                color: Colors.white,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: _buildVehicleList(userProvider),
                    ),
                    Expanded(
                        child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton(
                            heroTag: 'Admin page cancel',
                            onPressed: () {
                              onSelect(null);
                            },
                            child: const Icon(Icons.cancel),
                          ),
                          const SizedBox(width: 10),
                          FloatingActionButton(
                            heroTag: 'Admin page shuffle',
                            onPressed: _randomizeMarkersAndCircles,
                            child: const Icon(Icons.shuffle),
                          ),
                        ],
                      ),
                    ))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(UserProvider userProvider) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : !_getSucceed
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
                itemCount: _vehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicles[index];
                  return Card(
                    color: ifSelected(vehicle.vehicleId.toString())
                        ? Colors.red.shade300
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
                      onTap: () => onSelect(vehicle),
                    ),
                  );
                },
              );
  }

  @override
  bool get wantKeepAlive => true;
}
