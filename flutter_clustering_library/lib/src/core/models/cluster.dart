import "package:equatable/equatable.dart";
import "package:latlong2/latlong.dart";
import "package:meta/meta.dart";
import "package:flutter_map/flutter_map.dart";

import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";

/// Generic cluster that can contain any type of ClusterableItem
@immutable
class Cluster<T extends ClusterableItem> extends Equatable {
  /// Unique identifier for the cluster
  final String id;

  /// Center point of the cluster
  final LatLng center;

  /// Items contained in this cluster
  final List<T> items;

  /// Zoom level at which this cluster was created
  final double zoomLevel;

  /// Whether this cluster is expanded to show individual items
  final bool isExpanded;

  /// Optional metadata for the cluster
  final Map<String, dynamic> metadata;

  /// Timestamp when the cluster was created
  final DateTime createdAt;

  /// Optional bounds of the cluster
  final LatLngBounds? bounds;

  Cluster({
    required this.id,
    required this.center,
    required this.items,
    required this.zoomLevel,
    this.isExpanded = false,
    this.metadata = const {},
    DateTime? createdAt,
    this.bounds,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Number of items in the cluster
  int get count => items.length;

  /// Whether this cluster contains only a single item
  bool get isSingleItem => count == 1;

  /// First item in the cluster (useful for single-item clusters)
  T get firstItem => items.first;

  /// Total weight of all items in the cluster
  double get totalWeight => items.fold(0.0, (sum, item) => sum + item.weight);

  /// Average weight of items in the cluster
  double get averageWeight => totalWeight / count;

  /// All unique categories in the cluster
  Set<String> get categories =>
      items.map((item) => item.category).where((category) => category != null).cast<String>().toSet();

  /// Creates a copy of this cluster with the given changes
  Cluster<T> copyWith({
    String? id,
    LatLng? center,
    List<T>? items,
    double? zoomLevel,
    bool? isExpanded,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    LatLngBounds? bounds,
  }) {
    return Cluster<T>(
      id: id ?? this.id,
      center: center ?? this.center,
      items: items ?? this.items,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isExpanded: isExpanded ?? this.isExpanded,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      bounds: bounds ?? this.bounds,
    );
  }

  /// Calculates the bounds of all items in the cluster
  LatLngBounds calculateBounds() {
    if (items.isEmpty) {
      return LatLngBounds.fromPoints([center]);
    }

    final locations = items.map((item) => item.location).toList();
    return LatLngBounds.fromPoints(locations);
  }

  /// Calculates the centroid of all items in the cluster
  LatLng calculateCentroid() {
    if (items.isEmpty) {
      return center;
    }

    double totalLat = 0.0;
    double totalLng = 0.0;
    double totalWeight = 0.0;

    for (final item in items) {
      final weight = item.weight;
      totalLat += item.location.latitude * weight;
      totalLng += item.location.longitude * weight;
      totalWeight += weight;
    }

    return LatLng(
      totalLat / totalWeight,
      totalLng / totalWeight,
    );
  }

  /// Calculates the average distance between all items in the cluster
  double calculateAverageDistance() {
    if (items.length <= 1) {
      return 0.0;
    }

    double totalDistance = 0.0;
    int pairCount = 0;

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        totalDistance += items[i].distanceTo(items[j]);
        pairCount++;
      }
    }

    return totalDistance / pairCount;
  }

  /// Calculates the maximum distance between any two items in the cluster
  double calculateMaxDistance() {
    if (items.length <= 1) {
      return 0.0;
    }

    double maxDistance = 0.0;

    for (int i = 0; i < items.length; i++) {
      for (int j = i + 1; j < items.length; j++) {
        final distance = items[i].distanceTo(items[j]);
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      }
    }

    return maxDistance;
  }

  /// Checks if the cluster contains an item with the given ID
  bool containsItem(String itemId) {
    return items.any((item) => item.id == itemId);
  }

  /// Finds an item in the cluster by ID
  T? findItem(String itemId) {
    try {
      return items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        center,
        items,
        zoomLevel,
        isExpanded,
        metadata,
        createdAt,
        bounds,
      ];

  @override
  String toString() {
    return "Cluster(id: $id, count: $count, center: $center, zoomLevel: $zoomLevel)";
  }
}
