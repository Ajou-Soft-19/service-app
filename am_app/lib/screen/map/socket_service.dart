import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/singleton/location_singleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';
import '../../model/api/dto/alert_info.dart';
import '../../model/singleton/alert_singleton.dart';

class SocketService extends TokenApiUtils {
  late IOWebSocketChannel _channel;
  final url = "${dotenv.env['SOCKET_SERVER_URL']}/ws/my-location";
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isUsingNavi = false;
  bool _isConnected = false;

  final jsonDecoder = StreamTransformer<String, dynamic>.fromHandlers(
    handleData: (String data, EventSink<dynamic> sink) {
      sink.add(jsonDecode(data));
    },
  );


  Future<void> initSocket(userProvider, vehicleProvider) async {
    if (isConnected) {
      close();
    }

    await _connectWithNoLogin();
    _initializeWithNoLogin();

    // socketService.emergencyVehicleUpdates.listen((data){
    //   print('Emergency vehicle data: $data');
    // });
  }

  Future<void> _connectWithNoLogin() async {
    try {
      final socket = await WebSocket.connect(url);

      _channel = IOWebSocketChannel(socket);
      _isConnected = true;
    } catch (e) {
      debugPrint('Error connecting to socket: $e');
    }
    debugPrint('Connected to socket');
  }

  void _initializeWithNoLogin() {
    debugPrint('Initializing Guest socket');
    final initMessage = {
      'requestType': 'INIT',
    };

    _channel.sink.add(jsonEncode(initMessage));

    _channel.stream.listen((message) {
      LatLng currentLocLatLng = LatLng(
        LocationSingleton().currentLocation!.latitude!,
        LocationSingleton().currentLocation!.longitude!,
      );
      debugPrint(
          'Current distance between Emer: ${currentLocLatLng.toString()})}');
      handleAlertMessage(message);
      debugPrint('Received: $message');
    }, onError: (error) {
      debugPrint('Error: $error');
    });
  }

  void handleAlertMessage(dynamic message) {
    Map<String, dynamic> parsedJson = jsonDecode(message);

    if (parsedJson['data']['code'] != 200) return;

    Map<String, dynamic> data = parsedJson['data']['data'];
    EmergencyPathData emergencyPathData = EmergencyPathData.fromJson(data);

    // Creating LatLng list from PathPoints
    List<LatLng> pathPoints = emergencyPathData.pathPoints
        .map((point) =>
        LatLng(point.location.latitude, point.location.longitude))
        .toList();

    AlertSingleton().updateVehicleData(
        emergencyPathData.licenseNumber,
        emergencyPathData.currentPathPoint,
        pathPoints
    );

    debugPrint('License Number: ${AlertSingleton().licenseNumber}');
    debugPrint('Vehicle Type: ${emergencyPathData.vehicleType}');
    debugPrint('Current Path Point: ${AlertSingleton().currentPathPoint}');
    debugPrint(
        'Path Points: ${AlertSingleton().pathPoints?.map((e) => 'location: $e')
            .join(', ')}');
    if(LocationSingleton().currentLocation != null) {
      LatLng currentLocLatLng = LatLng(
        LocationSingleton().currentLocation!.latitude!,
        LocationSingleton().currentLocation!.longitude!,
      );
      debugPrint(
          'Current distance between Emer: ${AlertSingleton().calculateDistance(
              AlertSingleton().pathPoints![AlertSingleton().currentPathPoint!],
              currentLocLatLng)}');
    }
  }


  void startSendingLocationData(Location location) {
    _locationSubscription?.cancel(); // Cancel any previous subscription

    _locationSubscription = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => location.getLocation())
        .listen((LocationData currentLocation) {
      final data = {
        'requestType': 'UPDATE',
        'data': {
          'longitude': currentLocation.longitude,
          'latitude': currentLocation.latitude,
          'isUsingNavi': _isUsingNavi,
          'meterPerSec': currentLocation.speed ?? 0.0,
          'direction': currentLocation.heading ?? 0.0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      };
      debugPrint("Sending data: $data");
      _channel.sink.add(jsonEncode(data));
    });
  }

  void setUsingNavi(bool isUsingNavi) {
    _isUsingNavi = isUsingNavi;
  }

  void close() {
    if (_isConnected == false) return;
    _isConnected = false;
    _locationSubscription?.cancel();
    _channel.sink.close();
    debugPrint('Socket closed');
  }

  bool get isConnected => _isConnected;
}
