import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/interfaces/clustering_logger.dart";
import "package:flutter_map_clustering/src/core/interfaces/clustering_strategy.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/core/models/clustering_parameters.dart";
import "package:flutter_map_clustering/src/core/utils/clustering_utils.dart";

/// Density-based clustering strategy (DBSCAN-like algorithm)
class DensityClusteringStrategy<T extends ClusterableItem> implements ClusteringStrategy<T> {
  final ClusteringLogger _logger;

  DensityClusteringStrategy({
    ClusteringLogger? logger,
  }) : _logger = logger ?? const NoOpClusteringLogger();

  @override
  String get name => "Density-based Clustering";

  @override
  String get description => "Clusters items based on density and minimum points requirement";

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

    _logger.info("Starting density-based clustering for ${items.length} items");

    final clusters = <Cluster<T>>[];
    final visited = <String>{};
    final clustered = <String>{};

    final threshold = getClusterDistanceThreshold(parameters);
    final minPoints = parameters.minClusterSize;

    for (final item in items) {
      if (visited.contains(item.id)) continue;

      visited.add(item.id);
      final neighbors = _getNeighbors(item, items, threshold);

      if (neighbors.length < minPoints) {
        // This is a noise point, create individual cluster
        if (!clustered.contains(item.id)) {
          final cluster = ClusteringUtils.createCluster([item], parameters);
          clusters.add(cluster);
          clustered.add(item.id);
        }
      } else {
        // This is a core point, create cluster
        final clusterItems = <T>[];
        final neighborQueue = List<T>.from(neighbors);

        while (neighborQueue.isNotEmpty) {
          final neighbor = neighborQueue.removeAt(0);
          if (!visited.contains(neighbor.id)) {
            visited.add(neighbor.id);
            final neighborNeighbors = _getNeighbors(neighbor, items, threshold);
            if (neighborNeighbors.length >= minPoints) {
              neighborQueue.addAll(neighborNeighbors);
            }
          }

          if (!clustered.contains(neighbor.id)) {
            clusterItems.add(neighbor);
            clustered.add(neighbor.id);
          }
        }

        if (clusterItems.isNotEmpty) {
          final cluster = ClusteringUtils.createCluster(clusterItems, parameters);
          clusters.add(cluster);
        }
      }
    }

    _logger.info("Generated ${clusters.length} clusters using density-based clustering");
    return clusters;
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

  List<T> _getNeighbors(T item, List<T> items, double threshold) {
    return items.where((other) {
      if (other.id == item.id) return false;
      return item.distanceTo(other) <= threshold;
    }).toList();
  }
}
