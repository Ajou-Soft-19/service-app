import 'dart:io';

import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/provider/vehicle_provider.dart';
import 'package:am_app/screen/asset/assets.dart';
import 'package:am_app/screen/main_page/tab_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  DateTime? lastPressed;

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
          if (!userProvider.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return const TabPage();
          }
        },
      ),
    );
  }

  Future<void> checkGPSPermission(BuildContext context) async {
    PermissionStatus gpsStatus = await Permission.location.status;
    debugPrint('GPS Permission status: $gpsStatus');

    if (await Permission.location.isPermanentlyDenied) {
      Assets().showPopupWithCallback(
          context,
          "GPS 권한이 없으면 위치 기반 서비스를 이용할 수 없습니다. 설정에서 GPS 권한을 허용해주세요.",
          openAppSettings);
    } else if (!gpsStatus.isGranted) {
      await Permission.location.request();
    }
  }
}
