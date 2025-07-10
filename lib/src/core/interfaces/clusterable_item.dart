import 'package:latlong2/latlong.dart';
import 'package:meta/meta.dart';

/// Interface for items that can be clustered based on location
@immutable
abstract class ClusterableItem {
  /// Unique identifier for the item
  String get id;

  /// Location of the item
  LatLng get location;

  /// Optional weight for clustering calculations (default: 1.0)
  double get weight => 1.0;

  /// Optional metadata that can be used for filtering or grouping
  Map<String, dynamic> get metadata => const {};

  /// Optional timestamp for temporal clustering
  DateTime? get timestamp => null;

  /// Optional category for grouped clustering
  String? get category => null;

  /// Determines if this item should be clustered with another item
  /// Override this method for custom clustering logic
  bool shouldClusterWith(ClusterableItem other) => true;

  /// Distance calculation method (can be overridden for custom distance calculations)
  double distanceTo(ClusterableItem other) {
    final distance = const Distance();
    return distance.as(LengthUnit.Meter, location, other.location);
  }
}
