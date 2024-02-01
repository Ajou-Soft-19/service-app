import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:am_app/model/api/exception/token_expired.dart';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

class SocketService extends TokenApiUtils {
  late IOWebSocketChannel _channel;
  final url = "${dotenv.env['SOCKET_SERVER_URL']}/ws/my-location";
  StreamSubscription<LocationData>? _locationSubscription;

  late String? _jwt;
  late int? _vehicleId;
  bool _isConnected = false;

  Future<void> initSocket(userProvider, vehicleProvider) async {
    if (isConnected) {
      close();
    }

    debugPrint('Initializing socket');
    // 비회원 소켓
    if (vehicleProvider.vehicleId == null || userProvider.accessToken == null) {
      await _connectWithNoLogin();
      _initializeWithNoLogin();
      return;
    }

    try {
      await checkLoginStatus(userProvider);
    } on TokenExpiredException {
      debugPrint('Token expired');
      return;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return;
    }

    //회원 소켓
    await _connectWithLogin(userProvider.accessToken);
    _initializeWithLogin(
      int.parse(vehicleProvider.vehicleId!),
    );

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
  }

  Future<void> _connectWithLogin(String jwt) async {
    _jwt = jwt;
    try {
      final socket = await WebSocket.connect(url, headers: {
        'Authorization': 'Bearer $jwt',
      });

      _channel = IOWebSocketChannel(socket);
      _isConnected = true;
    } catch (e) {
      debugPrint('Error connecting to socket: $e');
    }
  }

  void _initializeWithNoLogin() {
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

  void _initializeWithLogin(int vehicleId) {
    _vehicleId = vehicleId;

    final initMessage = {
      'requestType': 'INIT',
      'jwt': 'Bearer $_jwt',
      'data': {
        'vehicleId': _vehicleId,
      },
    };

    _channel.sink.add(jsonEncode(initMessage));

    _channel.stream.listen((message) {
      debugPrint('Received: $message');
    }, onError: (error) {
      debugPrint('Error: $error');
    });
  }

  void startSendingLocationData(LocationData locationData, bool isUsingNavi) {
    _locationSubscription?.cancel(); // Cancel any previous subscription

    _locationSubscription = Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => Future.value(locationData))
        .listen((LocationData currentLocation) {
      final data = {
        'requestType': 'UPDATE',
        'data': {
          'longitude': currentLocation.longitude,
          'latitude': currentLocation.latitude,
          'isUsingNavi': isUsingNavi,
          'meterPerSec': currentLocation.speed,
          'direction': currentLocation.heading,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      debugPrint("Sending data: $data"); // Log the data being sent
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
//
// final jsonDecoder = StreamTransformer<String, dynamic>.fromHandlers(
//   handleData: (String data, EventSink<dynamic> sink) {
//     sink.add(jsonDecode(data));
//   },
// );
