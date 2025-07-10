import "dart:math" as math;
import "package:equatable/equatable.dart";
import "package:latlong2/latlong.dart";
import "package:meta/meta.dart";

/// Represents the geographical bounds of a cluster
@immutable
class ClusterBounds extends Equatable {
  /// North-east corner of the bounds
  final LatLng northEast;

  /// South-west corner of the bounds
  final LatLng southWest;

  const ClusterBounds({
    required this.northEast,
    required this.southWest,
  });

  /// Center point of the bounds
  LatLng get center => LatLng(
        (northEast.latitude + southWest.latitude) / 2,
        (northEast.longitude + southWest.longitude) / 2,
      );

  /// Latitude span of the bounds
  double get latitudeSpan => northEast.latitude - southWest.latitude;

  /// Longitude span of the bounds
  double get longitudeSpan => northEast.longitude - southWest.longitude;

  /// Area of the bounds in square degrees
  double get area => latitudeSpan * longitudeSpan;

  /// Whether the bounds contain the given point
  bool contains(LatLng point) {
    return point.latitude >= southWest.latitude &&
        point.latitude <= northEast.latitude &&
        point.longitude >= southWest.longitude &&
        point.longitude <= northEast.longitude;
  }

  /// Expands the bounds to include the given point
  ClusterBounds expandToInclude(LatLng point) {
    return ClusterBounds(
      northEast: LatLng(
        point.latitude > northEast.latitude ? point.latitude : northEast.latitude,
        point.longitude > northEast.longitude ? point.longitude : northEast.longitude,
      ),
      southWest: LatLng(
        point.latitude < southWest.latitude ? point.latitude : southWest.latitude,
        point.longitude < southWest.longitude ? point.longitude : southWest.longitude,
      ),
    );
  }

  /// Creates bounds from a list of points
  static ClusterBounds fromPoints(List<LatLng> points) {
    if (points.isEmpty) {
      throw ArgumentError("Points list cannot be empty");
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    return ClusterBounds(
      northEast: LatLng(maxLat, maxLng),
      southWest: LatLng(minLat, minLng),
    );
  }

  /// Creates bounds from a single point with a radius
  static ClusterBounds fromPointWithRadius(LatLng point, double radiusInMeters) {
    const earthRadius = 6378137.0; // Earth's radius in meters
    const degreesToRadians = 3.14159265359 / 180.0;

    final latRadians = point.latitude * degreesToRadians;
    final lngRadians = point.longitude * degreesToRadians;

    final deltaLat = radiusInMeters / earthRadius / degreesToRadians;
    final deltaLng = radiusInMeters / (earthRadius * math.cos(latRadians)) / degreesToRadians;

    return ClusterBounds(
      northEast: LatLng(point.latitude + deltaLat, point.longitude + deltaLng),
      southWest: LatLng(point.latitude - deltaLat, point.longitude - deltaLng),
    );
  }

  /// Checks if these bounds intersect with another bounds
  bool intersects(ClusterBounds other) {
    return !(other.southWest.latitude > northEast.latitude ||
        other.northEast.latitude < southWest.latitude ||
        other.southWest.longitude > northEast.longitude ||
        other.northEast.longitude < southWest.longitude);
  }

  /// Calculates the intersection of this bounds with another bounds
  ClusterBounds? intersection(ClusterBounds other) {
    if (!intersects(other)) {
      return null;
    }

    final maxSouthWestLat =
        southWest.latitude > other.southWest.latitude ? southWest.latitude : other.southWest.latitude;
    final maxSouthWestLng =
        southWest.longitude > other.southWest.longitude ? southWest.longitude : other.southWest.longitude;
    final minNorthEastLat =
        northEast.latitude < other.northEast.latitude ? northEast.latitude : other.northEast.latitude;
    final minNorthEastLng =
        northEast.longitude < other.northEast.longitude ? northEast.longitude : other.northEast.longitude;

    return ClusterBounds(
      northEast: LatLng(minNorthEastLat, minNorthEastLng),
      southWest: LatLng(maxSouthWestLat, maxSouthWestLng),
    );
  }

  /// Calculates the union of this bounds with another bounds
  ClusterBounds union(ClusterBounds other) {
    return ClusterBounds(
      northEast: LatLng(
        northEast.latitude > other.northEast.latitude ? northEast.latitude : other.northEast.latitude,
        northEast.longitude > other.northEast.longitude ? northEast.longitude : other.northEast.longitude,
      ),
      southWest: LatLng(
        southWest.latitude < other.southWest.latitude ? southWest.latitude : other.southWest.latitude,
        southWest.longitude < other.southWest.longitude ? southWest.longitude : other.southWest.longitude,
      ),
    );
  }

  @override
  List<Object?> get props => [northEast, southWest];

  @override
  String toString() {
    return "ClusterBounds(northEast: $northEast, southWest: $southWest)";
  }
}
