
import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";
import "package:flutter_clustering_library/src/core/interfaces/clustering_logger.dart";
import "package:flutter_clustering_library/src/core/interfaces/clustering_strategy.dart";
import "package:flutter_clustering_library/src/core/models/cluster.dart";
import "package:flutter_clustering_library/src/core/models/clustering_parameters.dart";
import "package:flutter_clustering_library/src/core/utils/clustering_utils.dart";
import "package:flutter_clustering_library/src/core/utils/distance_calculator.dart";
import "package:flutter_clustering_library/src/spatial_indexing/quadtree_spatial_index.dart";

/// Distance-based clustering strategy with spatial indexing optimization
class DistanceClusteringStrategy<T extends ClusterableItem> implements ClusteringStrategy<T> {
  final ClusteringLogger _logger;

  DistanceClusteringStrategy({
    ClusteringLogger? logger,
  }) : _logger = logger ?? const NoOpClusteringLogger();

  @override
  String get name => "Distance-based Clustering";

  @override
  String get description => "Clusters items based on distance threshold with spatial indexing optimization";

  @override
  Set<String> get supportedParameters => {
        "zoomLevel",
        "maxClusterDistance",
        "minClusterSize",
        "maxClusterSize",
        "enableSpatialIndexing",
        "enableIncrementalClustering",
        "distanceWeightFactor",
      };

  @override
  Future<List<Cluster<T>>> calculateClusters({
    required List<T> items,
    required ClusteringParameters parameters,
  }) async {
    if (items.isEmpty) {
      return [];
    }

    if (!ClusteringUtils.shouldEnableClustering(items, parameters)) {
      return _createIndividualClusters(items, parameters);
    }

    _logger.info("Starting distance-based clustering for ${items.length} items");

    final stopwatch = Stopwatch()..start();

    List<Cluster<T>> clusters;

    if (parameters.enableSpatialIndexing && items.length > 100) {
      clusters = await _clusterWithSpatialIndexing(items, parameters);
    } else {
      clusters = await _clusterWithoutSpatialIndexing(items, parameters);
    }

    stopwatch.stop();
    _logger.info("Distance-based clustering completed in ${stopwatch.elapsedMilliseconds}ms. "
        "Generated ${clusters.length} clusters from ${items.length} items");

    return clusters;
  }

  @override
  bool shouldClusterItems(T item1, T item2, ClusteringParameters parameters) {
    return ClusteringUtils.shouldClusterItems(item1, item2, parameters);
  }

  @override
  double getClusterDistanceThreshold(ClusteringParameters parameters) {
    return parameters.getEffectiveClusterDistance();
  }

  @override
  bool validateParameters(ClusteringParameters parameters) {
    return parameters.isValid();
  }

  /// Creates individual clusters for each item
  List<Cluster<T>> _createIndividualClusters(List<T> items, ClusteringParameters parameters) {
    return items.map((item) {
      return ClusteringUtils.createCluster([item], parameters);
    }).toList();
  }

  /// Clusters items using spatial indexing for improved performance
  Future<List<Cluster<T>>> _clusterWithSpatialIndexing(
    List<T> items,
    ClusteringParameters parameters,
  ) async {
    final bounds = ClusteringUtils.calculateItemsBounds(items);
    final spatialIndex = QuadTreeSpatialIndex<T>(bounds: bounds);

    // Build spatial index
    spatialIndex.insertAll(items);

    final clusters = <Cluster<T>>[];
    final processed = <String>{};
    final threshold = getClusterDistanceThreshold(parameters);

    for (final item in items) {
      if (processed.contains(item.id)) continue;

      // Find nearby items using spatial index
      final nearbyItems = spatialIndex.findNearby(item.location, threshold);
      final clusterItems = <T>[item];
      processed.add(item.id);

      // Group nearby items that should be clustered
      for (final nearbyItem in nearbyItems) {
        if (processed.contains(nearbyItem.id)) continue;
        if (nearbyItem.id == item.id) continue;

        if (shouldClusterItems(item, nearbyItem, parameters)) {
          clusterItems.add(nearbyItem);
          processed.add(nearbyItem.id);
        }
      }

      // Create cluster if it meets minimum size requirements
      if (clusterItems.length >= parameters.minClusterSize || clusterItems.length == 1) {
        final cluster = ClusteringUtils.createCluster(clusterItems, parameters);

        // Split cluster if it exceeds maximum size
        if (parameters.maxClusterSize != null && cluster.count > parameters.maxClusterSize!) {
          clusters.addAll(ClusteringUtils.splitCluster(cluster, parameters));
        } else {
          clusters.add(cluster);
        }
      }
    }

    return clusters;
  }

  /// Clusters items without spatial indexing (O(n²) algorithm)
  Future<List<Cluster<T>>> _clusterWithoutSpatialIndexing(
    List<T> items,
    ClusteringParameters parameters,
  ) async {
    final clusters = <Cluster<T>>[];
    final processed = <String>{};

    for (int i = 0; i < items.length; i++) {
      if (processed.contains(items[i].id)) continue;

      final clusterItems = <T>[items[i]];
      processed.add(items[i].id);

      // Find all items within clustering distance
      for (int j = i + 1; j < items.length; j++) {
        if (processed.contains(items[j].id)) continue;

        if (shouldClusterItems(items[i], items[j], parameters)) {
          clusterItems.add(items[j]);
          processed.add(items[j].id);
        }
      }

      // Create cluster if it meets minimum size requirements
      if (clusterItems.length >= parameters.minClusterSize || clusterItems.length == 1) {
        final cluster = ClusteringUtils.createCluster(clusterItems, parameters);

        // Split cluster if it exceeds maximum size
        if (parameters.maxClusterSize != null && cluster.count > parameters.maxClusterSize!) {
          clusters.addAll(ClusteringUtils.splitCluster(cluster, parameters));
        } else {
          clusters.add(cluster);
        }
      }
    }

    return clusters;
  }

  /// Optimized clustering for incremental updates
  Future<List<Cluster<T>>> calculateIncrementalClusters({
    required List<T> existingItems,
    required List<T> newItems,
    required List<Cluster<T>> existingClusters,
    required ClusteringParameters parameters,
  }) async {
    if (newItems.isEmpty) {
      return existingClusters;
    }

    _logger.info("Starting incremental clustering for ${newItems.length} new items");

    final affectedClusters = <Cluster<T>>{};
    final threshold = getClusterDistanceThreshold(parameters);

    // Find existing clusters that might be affected by new items
    for (final newItem in newItems) {
      for (final cluster in existingClusters) {
        final distance = DistanceCalculator.calculateDistance(newItem.location, cluster.center);
        if (distance <= threshold * 2) {
          // Use larger threshold for potential merging
          affectedClusters.add(cluster);
        }
      }
    }

    // Extract items from affected clusters
    final affectedItems = <T>[];
    for (final cluster in affectedClusters) {
      affectedItems.addAll(cluster.items);
    }

    // Add new items to affected items
    affectedItems.addAll(newItems);

    // Recluster affected items
    final newClusters = await calculateClusters(
      items: affectedItems,
      parameters: parameters,
    );

    // Combine unaffected clusters with new clusters
    final result = <Cluster<T>>[];
    for (final cluster in existingClusters) {
      if (!affectedClusters.contains(cluster)) {
        result.add(cluster);
      }
    }
    result.addAll(newClusters);

    return result;
  }

  /// Calculates clustering statistics for performance monitoring
  Map<String, dynamic> calculatePerformanceStats(
    List<T> items,
    List<Cluster<T>> clusters,
    Duration processingTime,
  ) {
    final stats = ClusteringUtils.calculateClusteringStats(clusters);

    return {
      ...stats,
      "processingTimeMs": processingTime.inMilliseconds,
      "itemsPerSecond": items.length / (processingTime.inMilliseconds / 1000),
      "compressionRatio": clusters.length / items.length,
      "averageDistanceReduction": _calculateAverageDistanceReduction(items, clusters),
    };
  }

  double _calculateAverageDistanceReduction(List<T> items, List<Cluster<T>> clusters) {
    if (clusters.isEmpty) return 0.0;

    double totalOriginalDistance = 0.0;
    double totalClusterDistance = 0.0;
    int pairCount = 0;

    for (final cluster in clusters) {
      if (cluster.items.length > 1) {
        totalOriginalDistance += cluster.calculateAverageDistance();
        totalClusterDistance += 0.0; // Clustered items have 0 visual distance
        pairCount++;
      }
    }

    return pairCount > 0 ? (totalOriginalDistance - totalClusterDistance) / pairCount : 0.0;
  }
}
