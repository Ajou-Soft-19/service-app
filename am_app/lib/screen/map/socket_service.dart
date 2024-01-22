import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:location/location.dart';

class SocketService {
  final WebSocketChannel _channel;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  SocketService(String url) : _channel = WebSocketChannel.connect(Uri.parse(url));

  void startSendingLocationData() {
    _locationSubscription?.cancel();  // Cancel any previous subscription

    _locationSubscription = Stream.periodic(Duration(seconds: 10)).asyncMap((_) => _location.getLocation()).listen((LocationData currentLocation) {
      final data = {
        'heading': currentLocation.heading,
        'speed': currentLocation.speed,
        'longitude': currentLocation.longitude,
        'latitude': currentLocation.latitude,
      };

      _channel.sink.add(jsonEncode(data));
    });
  }

  Stream<dynamic> get emergencyVehicleUpdates => _channel.stream.transform(jsonDecoder);

  void close() {
    _locationSubscription?.cancel();
    _channel.sink.close();
  }
}

final jsonDecoder = StreamTransformer<String, dynamic>.fromHandlers(
  handleData: (String data, EventSink<dynamic> sink) {
    sink.add(jsonDecode(data));
  },
);
