import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:am_app/model/api/token_api_utils.dart';
import 'package:am_app/model/provider/user_provider.dart';
import 'package:am_app/model/socket/socket_message_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

class EmergencySocketConnector extends TokenApiUtils {
  final url = "${dotenv.env['SOCKET_SERVER_URL']}/ws/my-location";
  late IOWebSocketChannel _channel;
  final SocketMessageHandler _socketMessageHandler = SocketMessageHandler();
  late UserProvider userProvider;
  bool _isUsingNavi = false;
  bool _isConnected = false;
  bool _isClosing = false;
  double _direction = 0.0;

  late final int? _vehicleId;

  EmergencySocketConnector(this.userProvider, this._vehicleId);

  final jsonDecoder = StreamTransformer<String, dynamic>.fromHandlers(
    handleData: (String data, EventSink<dynamic> sink) {
      sink.add(jsonDecode(data));
    },
  );

  Future<void> initSocket() async {
    const retryDuration = Duration(seconds: 5);

    while (true) {
      try {
        await checkEmergencyRole(userProvider);
        await checkLoginStatus(userProvider);
        await _connectWithLogin();
        if (isConnected) {
          _initializeWithLogin();
          break;
        }
      } catch (e) {
        debugPrint('Error connecting to socket: $e');
      } finally {
        await Future.delayed(retryDuration);
      }
    }
  }

  Future<void> _connectWithLogin() async {
    final socket = await WebSocket.connect(url,
        headers: await getHeaders(authRequired: true));
    _channel = IOWebSocketChannel(socket);
    _isConnected = true;
    debugPrint('Connected to socket');
  }

  void _initializeWithLogin() {
    debugPrint('Initializing Emergnecy socket');
    final initMessage = {
      'requestType': 'INIT',
      'data': {
        'vehicleId': _vehicleId,
      },
    };

    _channel.sink.add(jsonEncode(initMessage));

    _channel.stream.listen((message) {
      Map<String, dynamic> parsedJson = jsonDecode(message);
      String messageType = parsedJson['messageType'];
      debugPrint("Received message: $messageType");
      switch (messageType) {
        case 'RESPONSE':
          debugPrint(parsedJson.toString());
          _socketMessageHandler.handleResponseMessage(parsedJson);
          break;
        default:
          debugPrint('Unknown message type: $messageType');
          break;
      }
    }, onError: (error) async {
      debugPrint('Error: $error');
      debugPrint('Attempting to reconnect...');
      _isConnected = false;
      await initSocket();
    }, onDone: () async {
      debugPrint('Disconnected from socket');
      _isConnected = false;
      if (!_isClosing) {
        debugPrint('Attempting to reconnect...');
        await initSocket();
      }
    });
  }

  void sendLocationData(
      LocationData currentLocation, int? naviPathId, int? emergencyEventId) {
    if (!_isConnected) return;
    try {
      final data = {
        'requestType': 'UPDATE',
        'data': {
          'longitude': currentLocation.longitude,
          'latitude': currentLocation.latitude,
          'isUsingNavi': _isUsingNavi,
          'meterPerSec': currentLocation.speed ?? 0.0,
          'direction': _direction,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'onEmergency': emergencyEventId != 0,
          'naviPathId': naviPathId,
          'emergencyEventId': emergencyEventId,
        },
      };
      debugPrint("Sending data: $data");
      _channel.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint("Error sending data: $e");
    }
  }

  void close() {
    _isClosing = true;
    if (_isConnected == false) return;
    _isConnected = false;
    _channel.sink.close();
    debugPrint('Emergency Socket closed');
  }

  void setUsingNavi(bool isUsingNavi) {
    _isUsingNavi = isUsingNavi;
  }

  void setDirection(double direction) {
    _direction = direction;
  }

  bool get isConnected => _isConnected;
}
