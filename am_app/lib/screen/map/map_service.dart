import 'dart:math';

import 'package:am_app/model/api/dto/navigation_path.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';

class MapService {
  Future<Polyline> drawRoute(List<LatLng> route) async {
    List<LatLng> routePoints =
        route.map((point) => LatLng(point.latitude, point.longitude)).toList();

    Polyline routeLine = Polyline(
      polylineId: const PolylineId('route'),
      visible: true,
      points: routePoints,
      width: 6,
      color: Colors.blue,
    );
    return routeLine;
  }

  Future<Polyline> drawRouteRed(List<LatLng> route) async {
    List<LatLng> routePoints =
        route.map((point) => LatLng(point.latitude, point.longitude)).toList();

    Polyline routeLine = Polyline(
      polylineId: const PolylineId('route'),
      visible: true,
      points: routePoints,
      width: 8,
      color: Colors.red,
    );
    return routeLine;
  }

  Future<Polyline> drawRouteRedbyId(List<LatLng> route, String id) async {
    List<LatLng> routePoints =
        route.map((point) => LatLng(point.latitude, point.longitude)).toList();

    Polyline routeLine = Polyline(
      polylineId: PolylineId(id),
      visible: true,
      points: routePoints,
      width: 8,
      color: Colors.red,
    );
    return routeLine;
  }

  int ccw(Location a, Location b, Location c) {
    double op = a.longitude * b.latitude +
        b.longitude * c.latitude +
        c.longitude * a.latitude;
    op -= a.latitude * b.longitude +
        b.latitude * c.longitude +
        c.latitude * a.longitude;
    if (op > 0) {
      return 1; // 회전 방향이 반시계 방향인 경우
    } else if (op < 0)
      return -1; // 회전 방향이 시계 방향인 경우
    else
      return 0; // 세 점이 일직선 상에 있는 경우
  }

  bool doLinesIntersect(PathPoint a, PathPoint b, PathPoint c, PathPoint d) {
    int ab = ccw(a.location, b.location, c.location) *
        ccw(a.location, b.location, d.location);
    int cd = ccw(c.location, d.location, a.location) *
        ccw(c.location, d.location, b.location);
    if (ab == 0 && cd == 0) {
      if (a.location == b.location) {
        if (a.location == c.location || a.location == d.location) {
          return true;
        } else {
          return false;
        }
      }
      if (c.location == d.location) {
        if (c.location == a.location || c.location == b.location) {
          return true;
        } else {
          return false;
        }
      }
      if (max(a.location.longitude, b.location.longitude) <
          min(c.location.longitude, d.location.longitude)) return false;
      if (max(c.location.longitude, d.location.longitude) <
          min(a.location.longitude, b.location.longitude)) return false;
      if (max(a.location.latitude, b.location.latitude) <
          min(c.location.latitude, d.location.latitude)) return false;
      if (max(c.location.latitude, d.location.latitude) <
          min(a.location.latitude, b.location.latitude)) return false;
      return true;
    }
    return ab <= 0 && cd <= 0;
  }

  Future<bool> doPathsIntersect(
      List<PathPoint> path1, List<PathPoint> path2) async {
    for (int i = 0; i < path1.length - 1; i++) {
      for (int j = 0; j < path2.length - 1; j++) {
        if (doLinesIntersect(path1[i], path1[i + 1], path2[j], path2[j + 1])) {
          return true;
        }
      }
    }

    return false;
  }
}
