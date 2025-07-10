import "dart:math" as math;
import "package:latlong2/latlong.dart";

/// Utility class for calculating distances between geographic points
class DistanceCalculator {
  static const Distance _distance = Distance();

  /// Calculates the distance between two points in meters
  static double calculateDistance(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Meter, point1, point2);
  }

  /// Calculates the distance between two points in kilometers
  static double calculateDistanceKm(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Fast approximate distance calculation using the Haversine formula
  /// This is faster than the latlong2 library for bulk calculations
  static double haversineDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Very fast approximate distance calculation using the Equirectangular projection
  /// This is much faster but less accurate for large distances
  static double equirectangularDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final x = deltaLngRad * math.cos((lat1Rad + lat2Rad) / 2);
    final y = deltaLatRad;

    return earthRadius * math.sqrt(x * x + y * y);
  }

  /// Calculates the squared distance (avoids expensive sqrt operation)
  /// Useful for comparison operations where actual distance isn't needed
  static double squaredDistance(LatLng point1, LatLng point2) {
    final deltaLat = point2.latitude - point1.latitude;
    final deltaLng = point2.longitude - point1.longitude;
    return deltaLat * deltaLat + deltaLng * deltaLng;
  }

  /// Calculates the Manhattan distance (sum of absolute differences)
  /// Very fast but less accurate
  static double manhattanDistance(LatLng point1, LatLng point2) {
    const earthRadius = 6371000; // Earth's radius in meters
    const degreeToMeter = math.pi / 180 * earthRadius;

    final deltaLat = (point2.latitude - point1.latitude).abs();
    final deltaLng = (point2.longitude - point1.longitude).abs();

    return (deltaLat + deltaLng) * degreeToMeter;
  }

  /// Checks if two points are within a certain distance without calculating exact distance
  static bool isWithinDistance(LatLng point1, LatLng point2, double distanceMeters) {
    // Use squared distance for faster comparison
    final squaredThreshold = distanceMeters * distanceMeters;
    const earthRadius = 6371000; // Earth's radius in meters
    const degreeToMeter = math.pi / 180 * earthRadius;

    final deltaLat = (point2.latitude - point1.latitude) * degreeToMeter;
    final deltaLng = (point2.longitude - point1.longitude) * degreeToMeter;

    return (deltaLat * deltaLat + deltaLng * deltaLng) <= squaredThreshold;
  }

  /// Calculates the bearing between two points in degrees
  static double calculateBearing(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final y = math.sin(deltaLngRad) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) - math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLngRad);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  /// Calculates the midpoint between two points
  static LatLng calculateMidpoint(LatLng point1, LatLng point2) {
    final lat1Rad = point1.latitude * math.pi / 180;
    final lat2Rad = point2.latitude * math.pi / 180;
    final deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;

    final bx = math.cos(lat2Rad) * math.cos(deltaLngRad);
    final by = math.cos(lat2Rad) * math.sin(deltaLngRad);

    final lat3Rad = math.atan2(
      math.sin(lat1Rad) + math.sin(lat2Rad),
      math.sqrt((math.cos(lat1Rad) + bx) * (math.cos(lat1Rad) + bx) + by * by),
    );

    final lng3Rad = (point1.longitude * math.pi / 180) + math.atan2(by, math.cos(lat1Rad) + bx);

    return LatLng(
      lat3Rad * 180 / math.pi,
      lng3Rad * 180 / math.pi,
    );
  }

  /// Calculates the centroid of multiple points
  static LatLng calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError("Points list cannot be empty");
    }

    if (points.length == 1) {
      return points.first;
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  /// Calculates the weighted centroid of multiple points
  static LatLng calculateWeightedCentroid(List<LatLng> points, List<double> weights) {
    if (points.isEmpty) {
      throw ArgumentError("Points list cannot be empty");
    }

    if (points.length != weights.length) {
      throw ArgumentError("Points and weights lists must have the same length");
    }

    if (points.length == 1) {
      return points.first;
    }

    double totalLat = 0;
    double totalLng = 0;
    double totalWeight = 0;

    for (int i = 0; i < points.length; i++) {
      final weight = weights[i];
      totalLat += points[i].latitude * weight;
      totalLng += points[i].longitude * weight;
      totalWeight += weight;
    }

    return LatLng(
      totalLat / totalWeight,
      totalLng / totalWeight,
    );
  }
}
