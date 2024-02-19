import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/map/map_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as l;

import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  DateTime? lastPressed;
  bool _serviceEnabled = false;
  l.PermissionStatus _permissionGranted = l.PermissionStatus.denied;
  final l.Location _location = l.Location();

  @override
  void initState() {
    super.initState();
    checkGPSPermission(context);
    initProvider();
  }

  void initProvider() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final vehicleProvider =
        Provider.of<VehicleProvider>(context, listen: false);
    userProvider.initState();
    vehicleProvider.initState();
    userProvider.addListener(() {
      if (userProvider.accessToken == null) {
        final vehicleProvider =
            Provider.of<VehicleProvider>(context, listen: false);
        vehicleProvider.deleteState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (!userProvider.isLoaded ||
              _permissionGranted == l.PermissionStatus.denied) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return const MapPage();
          }
        },
      ),
    );
  }

  Future<void> checkGPSPermission(BuildContext context) async {
    PermissionStatus gpsStatus = await Permission.location.status;
    debugPrint('GPS Permission status: $gpsStatus');

    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == l.PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != l.PermissionStatus.granted) {
        return;
      }
    }

    if (await Permission.location.isPermanentlyDenied) {
      Assets().showPopupWithCallback(
          context, "GPS Permission Required", openAppSettings);
    } else if (!gpsStatus.isGranted) {
      await Permission.location.request();
    }

    setState(() {});
  }
}
