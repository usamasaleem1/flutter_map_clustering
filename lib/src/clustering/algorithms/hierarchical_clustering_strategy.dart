import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/interfaces/clustering_logger.dart";
import "package:flutter_map_clustering/src/core/interfaces/clustering_strategy.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/core/models/clustering_parameters.dart";
import "package:flutter_map_clustering/src/core/utils/clustering_utils.dart";

/// Hierarchical clustering strategy using agglomerative clustering
class HierarchicalClusteringStrategy<T extends ClusterableItem> implements ClusteringStrategy<T> {
  final ClusteringLogger _logger;

  HierarchicalClusteringStrategy({
    ClusteringLogger? logger,
  }) : _logger = logger ?? const NoOpClusteringLogger();

  @override
  String get name => "Hierarchical Clustering";

  @override
  String get description => "Agglomerative hierarchical clustering with distance-based merging";

  @override
  Set<String> get supportedParameters => {
        "zoomLevel",
        "maxClusterDistance",
        "minClusterSize",
        "maxClusterSize",
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

    _logger.info("Starting hierarchical clustering for ${items.length} items");

    // Initialize each item as its own cluster
    final List<Cluster<T>> clusters = items.map((item) {
      return ClusteringUtils.createCluster([item], parameters);
    }).toList();

    final threshold = getClusterDistanceThreshold(parameters);

    // Merge clusters based on distance
    bool merged = true;
    while (merged && clusters.length > 1) {
      merged = false;
      double minDistance = double.infinity;
      int mergeIndex1 = -1;
      int mergeIndex2 = -1;

      // Find the closest pair of clusters
      for (int i = 0; i < clusters.length; i++) {
        for (int j = i + 1; j < clusters.length; j++) {
          final distance = _calculateClusterDistance(clusters[i], clusters[j]);
          if (distance < minDistance && distance <= threshold) {
            minDistance = distance;
            mergeIndex1 = i;
            mergeIndex2 = j;
          }
        }
      }

      // Merge the closest clusters if within threshold
      if (mergeIndex1 != -1 && mergeIndex2 != -1) {
        final mergedCluster = ClusteringUtils.mergeClusters(
          clusters[mergeIndex1],
          clusters[mergeIndex2],
          parameters,
        );

        // Remove the original clusters and add the merged one
        clusters.removeAt(mergeIndex2); // Remove larger index first
        clusters.removeAt(mergeIndex1);
        clusters.add(mergedCluster);
        merged = true;
      }
    }

    // Filter out clusters that are too small
    final filteredClusters = clusters.where((cluster) {
      return cluster.count >= parameters.minClusterSize;
    }).toList();

    _logger.info("Generated ${filteredClusters.length} clusters using hierarchical clustering");
    return filteredClusters;
  }

  @override
  bool shouldClusterItems(T item1, T item2, ClusteringParameters parameters) {
    return ClusteringUtils.shouldClusterItems(item1, item2, parameters);
  }

  @override
  double getClusterDistanceThreshold(ClusteringParameters parameters) {
    return ClusteringUtils.calculateOptimalDistanceThreshold(parameters);
  }

  @override
  bool validateParameters(ClusteringParameters parameters) {
    return parameters.isValid() && parameters.minClusterSize >= 1;
  }

  /// Calculate distance between two clusters using closest point method
  double _calculateClusterDistance(Cluster<T> cluster1, Cluster<T> cluster2) {
    double minDistance = double.infinity;

    for (final item1 in cluster1.items) {
      for (final item2 in cluster2.items) {
        final distance = item1.distanceTo(item2);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
    }

    return minDistance;
  }
}
