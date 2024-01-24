import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MapService {
  Future<Polyline> drawRoute(List<LatLng> route) async {
    List<LatLng> routePoints = route.map((point) => LatLng(point.latitude, point.longitude)).toList();

    Polyline routeLine = Polyline(
      polylineId: const PolylineId('route'),
      visible: true,
      points: routePoints,
      width: 2,
      color: Colors.blue,
    );
    return routeLine;

  }
}