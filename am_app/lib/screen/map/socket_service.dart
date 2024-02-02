import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

class SocketService extends TokenApiUtils {
  late IOWebSocketChannel _channel;
  final url = "${dotenv.env['SOCKET_SERVER_URL']}/ws/my-location";
  StreamSubscription<LocationData>? _locationSubscription;

  bool _isConnected = false;

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
      debugPrint('Received: $message');
    }, onError: (error) {
      debugPrint('Error: $error');
    });
  }

  void startSendingLocationData(Location location, bool isUsingNavi) {
    _locationSubscription?.cancel(); // Cancel any previous subscription

    _locationSubscription = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => location.getLocation())
        .listen((LocationData currentLocation) {
      final data = {
        'requestType': 'UPDATE',
        'data': {
          'longitude': currentLocation.longitude,
          'latitude': currentLocation.latitude,
          'isUsingNavi': isUsingNavi,
          'meterPerSec': currentLocation.speed ?? 0.0,
          'direction': currentLocation.heading ?? 0.0,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      };
      debugPrint("Sending data: $data");
      _channel.sink.add(jsonEncode(data));
    });
  }

  //
  // Stream<dynamic> get emergencyVehicleUpdates =>
  //     _channel.stream.transform(jsonDecoder);

  void close() {
    if (_isConnected == false) return;
    _isConnected = false;
    _locationSubscription?.cancel();
    _channel.sink.close();
    debugPrint('Socket closed');
  }

  bool get isConnected => _isConnected;
}
