import 'dart:math';

/// 위치 및 경로 계산 서비스
class LocationService {
  /// 두 좌표 간 거리 계산 (km)
  /// Haversine 공식 사용
  static double calculateDistance(
    double lat1, 
    double lon1, 
    double lat2, 
    double lon2,
  ) {
    const double earthRadius = 6371; // 지구 반지름 (km)
    
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180;
  }

  /// 이동 시간估算 (분)
  /// 평균 시속 30km (도심 기준)
  static int calculateTravelTimeMinutes(double distanceKm) {
    const double averageSpeedKmh = 30.0;
    final double hours = distanceKm / averageSpeedKmh;
    return (hours * 60).ceil();
  }

  /// 최적 출발 시간 계산
  /// - 현재 위치에서 병원까지 이동 시간
  /// - 알림 기준 시간 (예: 30분 전에 알림)
  static int calculateOptimalDepartureTime({
    required double homeLatitude,
    required double homeLongitude,
    required double hospitalLatitude,
    required double hospitalLongitude,
    required int notifyBeforeMinutes,
  }) {
    final double distance = calculateDistance(
      homeLatitude, 
      homeLongitude, 
      hospitalLatitude, 
      hospitalLongitude,
    );
    
    final int travelMinutes = calculateTravelTimeMinutes(distance);
    
    // 알림 기준 시간 = 이동 시간 + 알림 전 시간
    return travelMinutes + notifyBeforeMinutes;
  }

  /// 거리와 시간을 문자열로 반환
  static String getTravelInfo({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) {
    final double distance = calculateDistance(fromLat, fromLon, toLat, toLon);
    final int minutes = calculateTravelTimeMinutes(distance);
    
    String distanceStr;
    if (distance < 1) {
      distanceStr = '${(distance * 1000).round()}m';
    } else {
      distanceStr = '${distance.toStringAsFixed(1)}km';
    }
    
    if (minutes < 60) {
      return '$distanceStr (${minutes}분)';
    } else {
      final int hours = minutes ~/ 60;
      final int remainingMinutes = minutes % 60;
      return '$distanceStr (${hours}시간 ${remainingMinutes}분)';
    }
  }
}