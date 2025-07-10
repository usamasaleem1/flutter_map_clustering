import "dart:math" as math;
import "package:latlong2/latlong.dart" hide Distance, DistanceCalculator;
import "package:uuid/uuid.dart";

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/core/models/cluster_bounds.dart";
import "package:flutter_map_clustering/src/core/models/clustering_parameters.dart";
import "package:flutter_map_clustering/src/core/utils/distance_calculator.dart";

/// Utility class for clustering operations
class ClusteringUtils {
  static const Uuid _uuid = Uuid();

  /// Generates a unique ID for a cluster
  static String generateClusterId() => _uuid.v4();

  /// Calculates the optimal cluster distance threshold based on parameters
  static double calculateOptimalDistanceThreshold(ClusteringParameters parameters) {
    return parameters.getEffectiveClusterDistance();
  }

  /// Calculates the centroid of a list of clusterable items
  static LatLng calculateItemsCentroid<T extends ClusterableItem>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError("Items list cannot be empty");
    }

    if (items.length == 1) {
      return items.first.location;
    }

    final points = items.map((item) => item.location).toList();
    final weights = items.map((item) => item.weight).toList();

    return DistanceCalculator.calculateWeightedCentroid(points, weights);
  }

  /// Calculates the bounds of a list of clusterable items
  static ClusterBounds calculateItemsBounds<T extends ClusterableItem>(List<T> items) {
    if (items.isEmpty) {
      throw ArgumentError("Items list cannot be empty");
    }

    final points = items.map((item) => item.location).toList();
    return ClusterBounds.fromPoints(points);
  }

  /// Checks if items should be clustered based on distance and other criteria
  static bool shouldClusterItems<T extends ClusterableItem>(
    T item1,
    T item2,
    ClusteringParameters parameters,
  ) {
    // Check distance
    final distance = item1.distanceTo(item2);
    final threshold = calculateOptimalDistanceThreshold(parameters);

    if (distance > threshold) {
      return false;
    }

    // Check if items allow clustering with each other
    if (!item1.shouldClusterWith(item2) || !item2.shouldClusterWith(item1)) {
      return false;
    }

    // Check category clustering
    if (parameters.enableCategoryClustering) {
      if (item1.category != item2.category) {
        return false;
      }
    }

    // Check temporal clustering
    if (parameters.enableTemporalClustering) {
      final timestamp1 = item1.timestamp;
      final timestamp2 = item2.timestamp;

      if (timestamp1 != null && timestamp2 != null) {
        final timeDifference = timestamp1.difference(timestamp2).inMinutes.abs();
        if (timeDifference > parameters.temporalClusteringWindow) {
          return false;
        }
      }
    }

    return true;
  }

  /// Creates a cluster from a list of items
  static Cluster<T> createCluster<T extends ClusterableItem>(
    List<T> items,
    ClusteringParameters parameters,
  ) {
    if (items.isEmpty) {
      throw ArgumentError("Items list cannot be empty");
    }

    final id = generateClusterId();
    final center = calculateItemsCentroid(items);
    // final bounds = calculateItemsBounds(items);

    return Cluster<T>(
      id: id,
      center: center,
      items: items,
      zoomLevel: parameters.zoomLevel,
      isExpanded: items.length == 1,
      bounds: null, // TODO: Convert ClusterBounds to LatLngBounds
    );
  }

  /// Merges two clusters into a single cluster
  static Cluster<T> mergeClusters<T extends ClusterableItem>(
    Cluster<T> cluster1,
    Cluster<T> cluster2,
    ClusteringParameters parameters,
  ) {
    final mergedItems = [...cluster1.items, ...cluster2.items];
    return createCluster(mergedItems, parameters);
  }

  /// Splits a cluster into smaller clusters based on parameters
  static List<Cluster<T>> splitCluster<T extends ClusterableItem>(
    Cluster<T> cluster,
    ClusteringParameters parameters,
  ) {
    if (cluster.items.length <= parameters.minClusterSize) {
      return [cluster];
    }

    final maxClusterSize = parameters.maxClusterSize;
    if (maxClusterSize == null || cluster.items.length <= maxClusterSize) {
      return [cluster];
    }

    // Simple split: divide items into smaller groups
    final clusters = <Cluster<T>>[];
    final itemGroups = _splitItemsIntoGroups(cluster.items, maxClusterSize);

    for (final group in itemGroups) {
      clusters.add(createCluster(group, parameters));
    }

    return clusters;
  }

  /// Splits items into groups of maximum size
  static List<List<T>> _splitItemsIntoGroups<T extends ClusterableItem>(
    List<T> items,
    int maxGroupSize,
  ) {
    final groups = <List<T>>[];

    for (int i = 0; i < items.length; i += maxGroupSize) {
      final end = math.min(i + maxGroupSize, items.length);
      groups.add(items.sublist(i, end));
    }

    return groups;
  }

  /// Filters items based on bounds
  static List<T> filterItemsByBounds<T extends ClusterableItem>(
    List<T> items,
    ClusterBounds bounds,
  ) {
    return items.where((item) => bounds.contains(item.location)).toList();
  }

  /// Filters items based on category
  static List<T> filterItemsByCategory<T extends ClusterableItem>(
    List<T> items,
    String category,
  ) {
    return items.where((item) => item.category == category).toList();
  }

  /// Filters items based on time range
  static List<T> filterItemsByTimeRange<T extends ClusterableItem>(
    List<T> items,
    DateTime startTime,
    DateTime endTime,
  ) {
    return items.where((item) {
      final timestamp = item.timestamp;
      if (timestamp == null) return false;
      return timestamp.isAfter(startTime) && timestamp.isBefore(endTime);
    }).toList();
  }

  /// Calculates the density of items in a given area
  static double calculateDensity<T extends ClusterableItem>(
    List<T> items,
    ClusterBounds bounds,
  ) {
    if (items.isEmpty || bounds.area == 0) {
      return 0.0;
    }

    final itemsInBounds = filterItemsByBounds(items, bounds);
    return itemsInBounds.length / bounds.area;
  }

  /// Finds the nearest neighbor for each item
  static Map<T, T?> findNearestNeighbors<T extends ClusterableItem>(
    List<T> items,
  ) {
    final neighbors = <T, T?>{};

    for (final item in items) {
      T? nearest;
      double minDistance = double.infinity;

      for (final other in items) {
        if (item.id == other.id) continue;

        final distance = item.distanceTo(other);
        if (distance < minDistance) {
          minDistance = distance;
          nearest = other;
        }
      }

      neighbors[item] = nearest;
    }

    return neighbors;
  }

  /// Calculates the average distance between items
  static double calculateAverageDistance<T extends ClusterableItem>(
    List<T> items,
  ) {
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

  /// Validates clustering parameters
  static bool validateClusteringParameters(ClusteringParameters parameters) {
    return parameters.isValid();
  }

  /// Suggests optimal parameters based on items
  static ClusteringParameters suggestOptimalParameters<T extends ClusterableItem>(
    List<T> items,
    double zoomLevel,
  ) {
    if (items.isEmpty) {
      return ClusteringParameters(zoomLevel: zoomLevel);
    }

    // Calculate average distance to suggest cluster distance
    final averageDistance = calculateAverageDistance(items);
    final suggestedMaxDistance = averageDistance * 2; // Double the average

    // Suggest minimum cluster size based on density
    final bounds = calculateItemsBounds(items);
    final density = calculateDensity(items, bounds);
    final suggestedMinClusterSize = density > 0.001 ? 3 : 2;

    return ClusteringParameters(
      zoomLevel: zoomLevel,
      maxClusterDistance: suggestedMaxDistance,
      minClusterSize: suggestedMinClusterSize,
      enableSpatialIndexing: items.length > 100,
      enableIncrementalClustering: items.length > 50,
    );
  }

  /// Checks if clustering is beneficial based on item count and parameters
  static bool shouldEnableClustering<T extends ClusterableItem>(
    List<T> items,
    ClusteringParameters parameters,
  ) {
    // Don't cluster if too few items
    if (items.length < parameters.minClusterSize) {
      return false;
    }

    // Don't cluster at very high zoom levels
    if (parameters.zoomLevel >= parameters.individualItemsZoomThreshold) {
      return false;
    }

    // Don't cluster at very low zoom levels
    if (parameters.zoomLevel <= parameters.minClusteringZoomThreshold) {
      return false;
    }

    return true;
  }

  /// Calculates clustering statistics
  static Map<String, dynamic> calculateClusteringStats<T extends ClusterableItem>(
    List<Cluster<T>> clusters,
  ) {
    if (clusters.isEmpty) {
      return {
        "totalClusters": 0,
        "totalItems": 0,
        "averageClusterSize": 0.0,
        "largestClusterSize": 0,
        "smallestClusterSize": 0,
        "singleItemClusters": 0,
        "multiItemClusters": 0,
      };
    }

    final totalItems = clusters.fold(0, (sum, cluster) => sum + cluster.count);
    final clusterSizes = clusters.map((cluster) => cluster.count).toList();
    final averageClusterSize = totalItems / clusters.length;
    final largestClusterSize = clusterSizes.reduce(math.max);
    final smallestClusterSize = clusterSizes.reduce(math.min);
    final singleItemClusters = clusters.where((cluster) => cluster.isSingleItem).length;
    final multiItemClusters = clusters.length - singleItemClusters;

    return {
      "totalClusters": clusters.length,
      "totalItems": totalItems,
      "averageClusterSize": averageClusterSize,
      "largestClusterSize": largestClusterSize,
      "smallestClusterSize": smallestClusterSize,
      "singleItemClusters": singleItemClusters,
      "multiItemClusters": multiItemClusters,
    };
  }
}
