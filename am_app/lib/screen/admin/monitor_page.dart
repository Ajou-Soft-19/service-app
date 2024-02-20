import 'dart:async';
import 'dart:io';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:am_app/model/api/dto/vehicle_status.dart';
import 'package:am_app/model/api/dto/warn_record.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/api/monitor_api.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
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

class _AdminPageState extends State<AdminPage> {
  Orientation? _originalOrientation;
  GoogleMapController? _controller;
  MonitorApi monitorApi = MonitorApi();
  final _mapService = MapService();

  // 차량 정보를 담을 리스트
  List<VehicleStatus> _emergencyVehicleInfo = [];
  VehicleStatus? selectedVehicleStatus;
  List<VehicleStatus> normalVehicles = [];
  List<VehicleStatus> emergencyVehicles = [];
  final Set<String> _warnedSessionIds = {};
  Timer? _vehicleStatusTimer;

  // 조회 옵션들
  bool _isLoading = true;
  bool _getSucceed = false;
  int _failureCount = 0;
  bool _showVehicleList = false;
  bool _showEmergencyVehicleInMap = false;
  bool _trackSelectedVehicle = false;

  // 구글맵에 표시할 마커 및 원을 담을 리스트
  final Set<Circle> _circles = <Circle>{};
  final Set<Marker> _markers = <Marker>{};
  final Set<Polyline> _polylines = {};
  NavigationData? navigationData;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _originalOrientation = MediaQuery.of(context).orientation;
    });
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _vehicleStatusTimer = Timer.periodic(
        const Duration(seconds: 2), (timer) => _updateVehicleStatus());
  }

  @override
  void dispose() {
    if (_originalOrientation == Orientation.portrait) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
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
      sleep(const Duration(milliseconds: 100));
      await _getSelectedWarnList(userProvider);
      setState(() {
        _getSucceed = true;
        _failureCount = 0;
      });
    } catch (e) {
      debugPrint('Error updating vehicle status: $e');
      _failureCount++;
      if (_failureCount == 5) {
        Assets().showErrorSnackBar(context, 'Failed to update vehicle status');
        setState(() {
          _getSucceed = false;
        });
      }
    }
  }

  Future<void> _fetchVehicleStatus(UserProvider userProvider) async {
    if (_controller == null) return;
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

    var vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    vehicleStatuses.removeWhere((element) =>
        element.vehicleInfo != null &&
        element.vehicleInfo!.vehicleId.toString() == vehicleProvider.vehicleId);
    normalVehicles.clear();
    emergencyVehicles.clear();
    for (var vehicleStatus in vehicleStatuses) {
      if (vehicleStatus.emergencyVehicle) {
        emergencyVehicles.add(vehicleStatus);
      } else {
        normalVehicles.add(vehicleStatus);
      }

      if (vehicleStatus == selectedVehicleStatus) {
        selectedVehicleStatus = vehicleStatus;
      }
    }
    debugPrint('Vehicle Count: ${vehicleStatuses.length}');
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

    var vehicleProvider = Provider.of<VehicleProvider>(context, listen: false);
    newVehicleStatuses.removeWhere((element) =>
        element.vehicleInfo != null &&
        element.vehicleInfo!.vehicleId.toString() == vehicleProvider.vehicleId);

    newVehicleStatuses.sort((a, b) {
      if (a == selectedVehicleStatus) return -1;
      if (b == selectedVehicleStatus) return 1;
      if (a.emergencyEventId != -1 && b.emergencyEventId == -1) return -1;
      if (b.emergencyEventId != -1 && a.emergencyEventId == -1) return 1;
      return DateTime.parse(a.lastUpdateTime)
          .compareTo(DateTime.parse(b.lastUpdateTime));
    });

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
    if (_trackSelectedVehicle) {
      double currentZoomLevel = await _controller!.getZoomLevel();
      await _controller!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(selectedVehicleStatus!.latitude,
                selectedVehicleStatus!.longitude),
            zoom: currentZoomLevel,
          ),
        ),
      );
    }
    if (navigationData == null) return;
    if (selectedVehicleStatus!.emergencyEventId == -1) return;
    int currentCheckPoint =
        await monitorApi.getEmergencyVehicleCurrentCheckPoint(
            userProvider, selectedVehicleStatus!);

    navigationData!.currentCheckPoint = currentCheckPoint;

    await _updateWranRecords(userProvider, currentCheckPoint);
    await drawCheckPoint();
  }

  Future<void> _updateWranRecords(
      UserProvider userProvider, int currentCheckPoint) async {
    if (selectedVehicleStatus == null) return;
    if (selectedVehicleStatus!.emergencyEventId == -1) return;
    List<WarnRecord> warnList =
        await monitorApi.getWarnRecordsByEmergencyEventIdAndCheckPointIndx(
            userProvider,
            selectedVehicleStatus!.emergencyEventId,
            currentCheckPoint);

    for (WarnRecord warn in warnList) {
      for (String sessionId in warn.sessionIds) {
        _warnedSessionIds.add(sessionId);
      }
    }
  }

  void _addVehicleMarkers(List<VehicleStatus> normalVehicles,
      List<VehicleStatus> emergencyVehicles, double radius) async {
    final BitmapDescriptor normalVehicleIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle_blue.png', radius, false);
    final BitmapDescriptor normalVehicleWarnedIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle_black.png', radius, false);
    final BitmapDescriptor emergencyVehicleIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle_red.png', radius, false);

    final BitmapDescriptor emergencyVehicleFocusIcon =
        await getBitmapDescriptorFromAssetBytesWithRadius(
            'assets/circle_red.png', radius, true);

    _markers.clear();

    for (var vehicleStatus in normalVehicles) {
      bool isWarned = _warnedSessionIds.contains(vehicleStatus.vehicleStatusId);
      BitmapDescriptor icon =
          isWarned ? normalVehicleWarnedIcon : normalVehicleIcon;
      _markers.add(
        Marker(
          markerId: MarkerId(
              'normal_${vehicleStatus.vehicleStatusId.substring(0, 7)}'),
          position: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          icon: icon,
          onTap: () => _showVehicleStatusDialog(vehicleStatus),
        ),
      );
    }

    for (var vehicleStatus in emergencyVehicles) {
      bool isFocused = selectedVehicleStatus == vehicleStatus;
      BitmapDescriptor icon =
          isFocused ? emergencyVehicleFocusIcon : emergencyVehicleIcon;
      _markers.add(
        Marker(
          markerId: MarkerId(
              'emergency_${vehicleStatus.vehicleStatusId.substring(0, 7)}'),
          position: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          icon: icon,
          onTap: () => _showVehicleStatusDialog(vehicleStatus),
        ),
      );
    }

    setState(() {});
  }

  void _showVehicleStatusDialog(VehicleStatus vehicleStatus) {
    String vehicleName = vehicleStatus.vehicleInfo?.licenseNumber ?? 'Guest';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            vehicleName,
            style: const TextStyle(
              color: Colors.indigo,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildVehicleStatusText(
                  'Session ID', vehicleStatus.vehicleStatusId),
              _buildVehicleStatusText('Vehicle ID',
                  vehicleStatus.vehicleInfo?.vehicleId.toString() ?? 'Unknown'),
              _buildVehicleStatusText('Latitude', '${vehicleStatus.latitude}'),
              _buildVehicleStatusText(
                  'Longitude', '${vehicleStatus.longitude}'),
              _buildVehicleStatusText('Speed',
                  '${(vehicleStatus.meterPerSec * 3.6).toStringAsFixed(2)} km/h'), // m/s를 km/h로 변환
              _buildVehicleStatusText('Direction',
                  '${vehicleStatus.direction.toStringAsFixed(2)}°'), // 소수점 두 자리까지 표시
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.indigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleStatusText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: <Widget>[
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _addCircle(LatLng position, double radius, Color color) {
    final circleId = 'circle_${_circles.length}';

    setState(() {
      _circles.add(
        Circle(
          circleId: CircleId(circleId),
          center: position,
          radius: radius,
          fillColor: color.withOpacity(0.5),
          strokeWidth: 1,
          strokeColor: color,
        ),
      );
    });
  }

  bool ifSelected(String? vehicleStatusId) {
    if (selectedVehicleStatus == null) return false;
    return selectedVehicleStatus!.vehicleStatusId.toString() == vehicleStatusId;
  }

  void onSelect(VehicleStatus? vehicleStatus, UserProvider userProvider) async {
    debugPrint('Selected vehicle: $vehicleStatus');
    bool moveCamera = false;

    if (vehicleStatus == null ||
        selectedVehicleStatus == null ||
        selectedVehicleStatus != vehicleStatus) {
      setState(() {
        selectedVehicleStatus = vehicleStatus;
        _polylines.clear();
        _circles.clear();
        _warnedSessionIds.clear();
      });
      moveCamera = true;
    } else if (selectedVehicleStatus == vehicleStatus) {
      setState(() {
        selectedVehicleStatus = null;
        _polylines.clear();
        _circles.clear();
        _warnedSessionIds.clear();
      });
    }

    if (!moveCamera || vehicleStatus == null) return;

    // TODO: 응급 상황인 응급차는 다르게 표시하기

    await _controller!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(vehicleStatus.latitude, vehicleStatus.longitude),
          zoom: 14.0,
        ),
      ),
    );

    await drawEmergencyPath(userProvider, vehicleStatus);
    await _getSelectedWarnList(userProvider);
  }

  Future<void> _getSelectedWarnList(UserProvider userProvider) async {
    if (selectedVehicleStatus == null) return;
    if (selectedVehicleStatus!.emergencyEventId == -1) return;
    List<WarnRecord> warnList =
        await monitorApi.getWarnRecordsByEmergencyEventId(
            userProvider, selectedVehicleStatus!.emergencyEventId);

    for (WarnRecord warn in warnList) {
      for (String sessionId in warn.sessionIds) {
        _warnedSessionIds.add(sessionId);
      }
    }
  }

  Future<void> drawEmergencyPath(
      UserProvider userProvider, VehicleStatus vehicleStatus) async {
    if (vehicleStatus.emergencyEventId == -1) return;
    try {
      navigationData = await monitorApi.getEmergencyNavigationPath(
          userProvider, vehicleStatus);
    } catch (e) {
      Assets().showErrorSnackBar(context, e.toString());
      return;
    }
    List<LatLng> routePoints = navigationData!.pathPointsToLatLng();
    Polyline newRoute = await _mapService.drawRouteRed(routePoints);
    setState(() {
      _polylines.clear();
      _polylines.add(newRoute);
    });

    await drawCheckPoint();
  }

  Future<void> drawCheckPoint() async {
    CheckPoint? nextCheckPoint = navigationData!.findNextCheckPoint();

    if (nextCheckPoint == null) return;

    _circles.clear();
    _addCircle(
        LatLng(nextCheckPoint.location.latitude,
            nextCheckPoint.location.longitude),
        500,
        Colors.blue);
    if (selectedVehicleStatus != null) {
      _addCircle(
          LatLng(selectedVehicleStatus!.latitude,
              selectedVehicleStatus!.longitude),
          170,
          Colors.red);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(userProvider),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.34998, 126.108605),
              zoom: 11.0,
            ),
            markers: _markers,
            circles: _circles,
            polylines: _polylines,
          ),
          if (_showVehicleList) _buildEmergencyVehicleList(userProvider),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(UserProvider userProvider) {
    return AppBar(
      backgroundColor: Colors.indigo,
      title: const Text(
        'Admin Monitoring Page',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        MaterialButton(
          onPressed: () async {
            await _loadEmergencyVehicles(userProvider);
            setState(() {
              _showVehicleList = !_showVehicleList;
            });
          },
          minWidth: 80.0,
          child: Icon(
            _showVehicleList ? Icons.close : Icons.list,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Align _buildEmergencyVehicleList(UserProvider userProvider) {
    double width = MediaQuery.of(context).size.width * 0.2;
    if (width < 250) width = 250;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.white],
          ),
        ),
        child: Column(
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Emergency Vehicles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const Divider(
              color: Colors.white,
              thickness: 2,
              indent: 10,
              endIndent: 10,
            ),
            Expanded(
              flex: 5,
              child: _buildVehicleList(userProvider),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: _buildListMenu(userProvider),
              ),
            ),
          ],
        ),
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
                        ? Colors.red[100]
                        : Colors.white,
                    elevation: 5,
                    margin: const EdgeInsets.all(7),
                    child: ListTile(
                      leading: vehicleStatus.emergencyEventId != -1
                          ? const Icon(Icons.warning_amber_outlined,
                              color: Colors.red, size: 40)
                          : Icon(getIconBasedOnVehicleType(vehicle.vehicleType),
                              color: Colors.indigo, size: 40),
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

  Widget _buildListMenu(UserProvider userProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Tooltip(
          message: 'Unselect vehicle',
          child: FloatingActionButton(
            heroTag: 'Admin page cancel',
            onPressed: () {
              onSelect(null, userProvider);
            },
            backgroundColor: Colors.red,
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
                      _showEmergencyVehicleInMap = !_showEmergencyVehicleInMap;
                    });
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.public_sharp),
                ),
              )
            : Tooltip(
                message: 'Load Emergency Vehicle In Map',
                child: FloatingActionButton(
                  heroTag: 'Admin page Toggle',
                  onPressed: () {
                    setState(() {
                      _showEmergencyVehicleInMap = !_showEmergencyVehicleInMap;
                    });
                  },
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.map),
                ),
              ),
        const SizedBox(width: 10),
        Tooltip(
          message: 'Track selected vehicle',
          child: FloatingActionButton(
            heroTag: 'Admin page track',
            onPressed: () {
              setState(() {
                _trackSelectedVehicle = !_trackSelectedVehicle;
              });
            },
            backgroundColor: _trackSelectedVehicle ? Colors.blue : Colors.white,
            child: const Icon(Icons.gps_fixed),
          ),
        ),
      ],
    );
  }
}
