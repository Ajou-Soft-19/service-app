import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:location/location.dart';

class SocketService {
  late IOWebSocketChannel _channel;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  late String? _jwt;
  late int? _vehicleId;

  SocketService(String url, String jwt) {
    WebSocket.connect(url, headers: {
      'Authorization': 'Bearer $jwt',
    }).then((socket) {
      _channel = IOWebSocketChannel(socket);
    });
  }

  void initialize(String jwt, int vehicleId) {
    _jwt = jwt;
    _vehicleId = vehicleId;

    final initMessage = {
      'requestType': 'INIT',
      'jwt': jwt,
      'data': {
        'vehicleId': vehicleId,
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

    _locationSubscription = Stream.periodic(Duration(seconds: 10))
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
