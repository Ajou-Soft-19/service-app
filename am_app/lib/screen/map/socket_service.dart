import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

class SocketService {
  late IOWebSocketChannel _channel;
  final Location _location = Location();
  final url = "${dotenv.env['SOCKET_SERVER_URL']}/ws/my-location";
  StreamSubscription<LocationData>? _locationSubscription;

  late String? _jwt;
  late int? _vehicleId;

  Future<void> connect(String jwt) async {
    _jwt = jwt;
    final socket = await WebSocket.connect(url, headers: {
      'Authorization': 'Bearer $jwt',
    });

    _channel = IOWebSocketChannel(socket);
  }

  void initialize(int vehicleId) {
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
      print('Received: $message');
    }, onError: (error) {
      print('Error: $error');
    });
  }

  void startSendingLocationData(LocationData locationData, bool isUsingNavi) {
    _locationSubscription?.cancel(); // Cancel any previous subscription

    _locationSubscription = Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => Future.value(locationData))
        .listen((LocationData currentLocation) {
      final data = {
        'requestType': 'UPDATE',
        'jwt': _jwt,
        'data': {
          'longitude': currentLocation.longitude,
          'latitude': currentLocation.latitude,
          'isUsingNavi': isUsingNavi,
          'meterPerSec': currentLocation.speed,
          'direction': currentLocation.heading,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
      print("Sending data: $data"); // Log the data being sent
      _channel.sink.add(jsonEncode(data));
    });
  }

  //
  // Stream<dynamic> get emergencyVehicleUpdates =>
  //     _channel.stream.transform(jsonDecoder);

  void close() {
    _locationSubscription?.cancel();
    _channel.sink.close();
  }
}
//
// final jsonDecoder = StreamTransformer<String, dynamic>.fromHandlers(
//   handleData: (String data, EventSink<dynamic> sink) {
//     sink.add(jsonDecode(data));
//   },
// );
