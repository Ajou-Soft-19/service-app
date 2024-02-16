import 'dart:math';

class CompassUtil {
  double calculateTrueNorth(double azimuth, double latitude, double longitude,
      double magneticDeclination) {
    // 각도를 라디안으로 변환
    final azimuthRadians = radians(azimuth);
    final latitudeRadians = radians(latitude);
    final longitudeRadians = radians(longitude);
    final magneticDeclinationRadians = radians(magneticDeclination);

    // 위치 벡터 계산
    final positionVector = [
      cos(latitudeRadians) * cos(longitudeRadians),
      cos(latitudeRadians) * sin(longitudeRadians),
      sin(latitudeRadians),
    ];

    final azimuthVector = [
      sin(azimuthRadians),
      -cos(azimuthRadians),
      0,
    ];

    // 회전 행렬 계산
    final rotationMatrix = [
      [cos(magneticDeclinationRadians), -sin(magneticDeclinationRadians)],
      [sin(magneticDeclinationRadians), cos(magneticDeclinationRadians)],
    ];

    // 진북 벡터 계산
    final trueNorthVector = List.generate(3, (index) => 0.0);
    for (var i = 0; i < 3; i++) {
      for (var j = 0; j < 3; j++) {
        trueNorthVector[i] += rotationMatrix[i][j] * azimuthVector[j];
      }
    }

    // 진북 방위각 계산
    final trueNorthAzimuthRadians =
        atan2(trueNorthVector[1], trueNorthVector[0]);

    // 라디안을 각도로 변환하고 0-360 범위로 정규화
    final trueNorthAzimuthDegrees = degrees(trueNorthAzimuthRadians) % 360.0;

    return trueNorthAzimuthDegrees;
  }

  double radians(double degrees) {
    return degrees * (pi / 180);
  }

  double degrees(double radians) {
    return radians * (180 / pi);
  }
}
