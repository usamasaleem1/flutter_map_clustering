import "package:latlong2/latlong.dart";

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster_bounds.dart";

/// Interface for spatial indexing data structures
abstract class SpatialIndex<T extends ClusterableItem> {
  /// Insert an item into the spatial index
  void insert(T item);

  /// Remove an item from the spatial index
  bool remove(T item);

  /// Update an item's location in the spatial index
  void update(T item);

  /// Clear all items from the spatial index
  void clear();

  /// Get all items within a certain distance from a point
  List<T> findNearby(LatLng point, double radiusMeters);

  /// Get all items within a bounding box
  List<T> findInBounds(ClusterBounds bounds);

  /// Get all items in the index
  List<T> getAllItems();

  /// Get the number of items in the index
  int get size;

  /// Check if the index is empty
  bool get isEmpty;

  /// Check if the index contains an item
  bool contains(T item);

  /// Get the bounds of all items in the index
  ClusterBounds? getBounds();

  /// Find the nearest neighbor to a given point
  T? findNearestNeighbor(LatLng point);

  /// Find the k nearest neighbors to a given point
  List<T> findKNearestNeighbors(LatLng point, int k);

  /// Bulk insert multiple items
  void insertAll(List<T> items);

  /// Bulk remove multiple items
  void removeAll(List<T> items);

  /// Optimize the index (rebuild, rebalance, etc.)
  void optimize();
}
