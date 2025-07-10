import "package:flutter_clustering_library/src/core/models/cluster.dart";
import "package:flutter_clustering_library/src/core/models/clustering_parameters.dart";
import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";

/// Interface for different clustering strategies
abstract class ClusteringStrategy<T extends ClusterableItem> {
  /// Name of the clustering strategy
  String get name;

  /// Description of the clustering strategy
  String get description;

  /// Calculate clusters for the given items with the specified parameters
  Future<List<Cluster<T>>> calculateClusters({
    required List<T> items,
    required ClusteringParameters parameters,
  });

  /// Checks if two items should be clustered together based on the strategy
  bool shouldClusterItems(T item1, T item2, ClusteringParameters parameters);

  /// Get the optimal cluster distance threshold for the given parameters
  double getClusterDistanceThreshold(ClusteringParameters parameters);

  /// Validates if the clustering parameters are valid for this strategy
  bool validateParameters(ClusteringParameters parameters);

  /// Returns the supported parameter types for this strategy
  Set<String> get supportedParameters;
}
