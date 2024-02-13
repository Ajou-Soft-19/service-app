// custom_google_map.dart 파일
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomGoogleMap extends StatelessWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng initialPosition;
  final Function onMapCreated;

  const CustomGoogleMap({
    super.key,
    required this.markers,
    required this.polylines,
    required this.initialPosition,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GoogleMap(
        compassEnabled: false,
        onMapCreated: (controller) => onMapCreated(controller),
        initialCameraPosition:
            CameraPosition(target: initialPosition, zoom: 18.0, tilt: 30.0),
        polylines: polylines,
        markers: markers,
        buildingsEnabled: false,
      ),
    ]);
  }
}
