import 'dart:async';
import 'dart:math';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/dto/vehicle.dart';
import 'package:am_app/model/api/dto/vehicle_status.dart';
import 'package:am_app/model/api/vehicle_api.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/screen/admin/monitor_api.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/image_resize.dart';
import 'package:am_app/screen/map/map_service.dart';
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
  MonitorApi monitorApi = MonitorApi();
  final _mapService = MapService();

  // 차량 정보를 담을 리스트
  List<VehicleStatus> _emergencyVehicleInfo = [];
  bool _isLoading = true;
  bool _getSucceed = false;
  bool _showVehicleList = false;
  bool _showEmergencyVehicleInMap = false;
  VehicleStatus? selectedVehicleStatus;
  List<VehicleStatus> normalVehicles = [];
  List<VehicleStatus> emergencyVehicles = [];
  Timer? _vehicleStatusTimer;

  // 구글맵에 표시할 마커 및 원을 담을 리스트
  final Set<Circle> _circles = <Circle>{};
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = {};
  NavigationData? navigationData;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // _addCircle(const LatLng(37.5665, 126.9780));
    _vehicleStatusTimer = Timer.periodic(
        const Duration(seconds: 2), (timer) => _updateVehicleStatus());
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _vehicleStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateVehicleStatus() async {
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    try {
      await _fetchVehicleStatus(userProvider);
      await _loadEmergencyVehicles(userProvider);
      await _updateSelectedVehiclePathPoint(userProvider);
      setState(() {
        _getSucceed = true;
      });
    } catch (e) {
      debugPrint('Error updating vehicle status: $e');
      setState(() {
        _getSucceed = false;
      });
    }
  }

  Future<void> _fetchVehicleStatus(UserProvider userProvider) async {
    if (_controller == null) return;
    debugPrint('Fetching vehicle status');
    LatLngBounds? bounds = await _controller!.getVisibleRegion();
    LatLng center = LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );

    double radius = monitorApi.calculateDistance(
          bounds.northeast.latitude,
          bounds.northeast.longitude,
          bounds.southwest.latitude,
          bounds.southwest.longitude,
        ) /
        2;
    List<VehicleStatus> vehicleStatuses = await monitorApi.getVehicleStatus(
        userProvider, center.latitude, center.longitude, radius * 1000);

    normalVehicles.clear();
    emergencyVehicles.clear();
    for (var vehicleStatus in vehicleStatuses) {
      if (vehicleStatus.emergencyVehicle) {
        emergencyVehicles.add(vehicleStatus);
      } else {
        normalVehicles.add(vehicleStatus);
      }
    }

    _addVehicleMarkers(normalVehicles, emergencyVehicles, radius);
  }

  Future<void> _loadEmergencyVehicles(UserProvider userProvider) async {
    List<VehicleStatus> newVehicleStatuses = [];

    if (_showEmergencyVehicleInMap) {
      newVehicleStatuses = emergencyVehicles;
    } else {
      try {
        newVehicleStatuses =
            await monitorApi.getAllEmergencyVehicleStatus(userProvider);
      } catch (e) {
        debugPrint('Error loading vehicles: $e');
        Assets().showErrorSnackBar(context, e.toString());
      }
    }

    if (!newVehicleStatuses.contains(selectedVehicleStatus)) {
      setState(() {
        selectedVehicleStatus = null;
        _polylines.clear();
        _circles.clear();
      });
    }

    setState(() {
      _emergencyVehicleInfo = newVehicleStatuses;
      _isLoading = false;
    });
  }

  Future<void> _updateSelectedVehiclePathPoint(
      UserProvider userProvider) async {
    if (selectedVehicleStatus == null) return;
    if (navigationData == null) return;
    int currentPathPoint = await monitorApi.getEmergencyVehicleCurrentPath(
        userProvider, selectedVehicleStatus!);

    navigationData!.currentPathPoint = currentPathPoint;

    await drawCheckPoint();
  }

  void _addVehicleMarkers(List<VehicleStatus> normalVehicles,
      List<VehicleStatus> emergencyVehicles, double radius) async {
    final BitmapDescriptor normalVehicleIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle.png', radius);
    final BitmapDescriptor emergencyVehicleIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle2.png', radius);

    debugPrint('Adding vehicle markers');
    debugPrint('Normal: ${normalVehicles.length}');
    debugPrint('Emergency: ${emergencyVehicles.length}');
    _markers.clear();

    for (var vehicleStatus in normalVehicles) {
      _markers.add(
        Marker(
          markerId: MarkerId(
              'normal_${vehicleStatus.vehicleStatusId.substring(0, 7)}'),
          position: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          icon: normalVehicleIcon,
          onTap: () => _showVehicleStatusDialog(vehicleStatus),
        ),
      );
    }

    for (var vehicleStatus in emergencyVehicles) {
      _markers.add(
        Marker(
          markerId: MarkerId(
              'emergency_${vehicleStatus.vehicleStatusId.substring(0, 7)}'),
          position: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          icon: emergencyVehicleIcon,
          onTap: () => _showVehicleStatusDialog(vehicleStatus),
        ),
      );
    }

    setState(() {});
  }

  void _showVehicleStatusDialog(VehicleStatus vehicleStatus) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Vehicle Status'),
          content: Text('Vehicle ID: ${vehicleStatus.vehicleStatusId}\n'
              'Latitude: ${vehicleStatus.latitude}\n'
              'Longitude: ${vehicleStatus.longitude}\n'
              'Speed: ${vehicleStatus.meterPerSec} m/s\n'
              'Direction: ${vehicleStatus.direction}°\n'),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addCircle(LatLng position) {
    final circleId = 'circle_${_circles.length}';

    setState(() {
      _circles.add(
        Circle(
          circleId: CircleId(circleId),
          center: position,
          radius: 1000,
          fillColor: Colors.blue.withOpacity(0.5),
          strokeWidth: 1,
          strokeColor: Colors.blue,
        ),
      );
    });
  }

  bool ifSelected(String? vehicleStatusId) {
    if (selectedVehicleStatus == null) return false;
    return selectedVehicleStatus!.vehicleStatusId.toString() == vehicleStatusId;
  }

  onSelect(VehicleStatus? vehicleStatus, UserProvider userProvider) async {
    bool moveCamera = false;

    if (vehicleStatus == null) {
      setState(() {
        selectedVehicleStatus = null;
        _polylines.clear();
        _circles.clear();
      });
    } else if (selectedVehicleStatus == null ||
        selectedVehicleStatus!.toString() != vehicleStatus.toString()) {
      setState(() {
        selectedVehicleStatus = vehicleStatus;
      });
      moveCamera = true;
    } else if (selectedVehicleStatus!.toString() == vehicleStatus.toString()) {
      setState(() {
        selectedVehicleStatus = null;
        _polylines.clear();
        _circles.clear();
      });
    }

    if (!moveCamera || vehicleStatus == null) return;
    // TODO: 응급 상황인 응급차는 다르게 표시하기
    //if (!vehicleStatus.onAction) return;

    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          zoom: 14.0,
        ),
      ),
    );

    await drawEmergencyPath(userProvider, vehicleStatus);
  }

  Future<void> drawEmergencyPath(
      UserProvider userProvider, VehicleStatus vehicleStatus) async {
    navigationData = await monitorApi.getEmergencyNavigationPath(
        userProvider, vehicleStatus);
    List<LatLng> routePoints = navigationData!.pathPointsToLatLng();
    Polyline newRoute = await _mapService.drawRouteRed(routePoints);
    setState(() {
      _polylines.clear();
      _polylines.add(newRoute);
    });

    // find next checkpoint
    await drawCheckPoint();
  }

  Future<void> drawCheckPoint() async {
    CheckPoint? nextCheckPoint = navigationData!.findNextCheckPoint();

    if (nextCheckPoint == null) return;

    setState(() {
      _circles.clear();
      _addCircle(LatLng(
          nextCheckPoint.location.latitude, nextCheckPoint.location.longitude));
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
              await _loadEmergencyVehicles(userProvider);
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
              target: LatLng(37.5665, 126.9780),
              zoom: 11.0,
            ),
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
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
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Emergency Vehicles',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: _buildVehicleList(userProvider),
                    ),
                    Expanded(
                        flex: 1,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Tooltip(
                                message: 'Unselect vehicle',
                                child: FloatingActionButton(
                                  heroTag: 'Admin page cancel',
                                  onPressed: () {
                                    onSelect(null, userProvider);
                                  },
                                  child: const Icon(Icons.cancel),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _showEmergencyVehicleInMap
                                  ? Tooltip(
                                      message: 'Load All Emergency Vehicle',
                                      child: FloatingActionButton(
                                        heroTag: 'Admin page Toggle2',
                                        onPressed: () {
                                          setState(() {
                                            _showEmergencyVehicleInMap =
                                                !_showEmergencyVehicleInMap;
                                          });
                                        },
                                        child: const Icon(Icons.public_sharp),
                                      ),
                                    )
                                  : Tooltip(
                                      message: 'Load Emergency Vehicle In Map',
                                      child: FloatingActionButton(
                                        heroTag: 'Admin page Toggle',
                                        onPressed: () {
                                          setState(() {
                                            _showEmergencyVehicleInMap =
                                                !_showEmergencyVehicleInMap;
                                          });
                                        },
                                        child: const Icon(Icons.map),
                                      ),
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
                itemCount: _emergencyVehicleInfo.length,
                itemBuilder: (context, index) {
                  final vehicleStatus = _emergencyVehicleInfo[index];
                  final vehicle = vehicleStatus.vehicleInfo;
                  if (vehicle == null) return const SizedBox.shrink();
                  return Card(
                    color: ifSelected(vehicleStatus.vehicleStatusId.toString())
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
                      onTap: () => onSelect(vehicleStatus, userProvider),
                    ),
                  );
                },
              );
  }

  @override
  bool get wantKeepAlive => true;
}
