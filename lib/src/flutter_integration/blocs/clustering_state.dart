import "package:equatable/equatable.dart";

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/core/models/clustering_parameters.dart";

/// Clustering status enumeration
enum ClusteringStatus {
  /// Initial state
  initial,

  /// Clustering is in progress
  loading,

  /// Clustering completed successfully
  loaded,

  /// Clustering failed
  error,

  /// Cluster was tapped
  clusterTapped,

  /// Individual item was tapped
  itemTapped,

  /// Benchmark is running
  benchmarking,

  /// Benchmark completed
  benchmarkCompleted,
}

/// Clustering state for Flutter BLoC
class ClusteringState<T extends ClusterableItem> extends Equatable {
  /// Current clustering status
  final ClusteringStatus status;

  /// Current clustering parameters
  final ClusteringParameters parameters;

  /// List of items to cluster
  final List<T> items;

  /// Generated clusters
  final List<Cluster<T>> clusters;

  /// Whether clustering is enabled
  final bool isEnabled;

  /// Current clustering strategy name
  final String? strategyName;

  /// Error message if clustering failed
  final String? errorMessage;

  /// Selected cluster when tapped
  final Cluster<T>? selectedCluster;

  /// Selected item when tapped
  final T? selectedItem;

  /// Filtering criteria
  final String? categoryFilter;
  final DateTime? startTimeFilter;
  final DateTime? endTimeFilter;

  /// Benchmark results
  final Map<String, dynamic>? benchmarkResults;

  /// Performance statistics
  final Map<String, dynamic>? performanceStats;

  /// Available clustering strategies
  final List<String> availableStrategies;

  const ClusteringState({
    this.status = ClusteringStatus.initial,
    this.parameters = const ClusteringParameters(),
    this.items = const [],
    this.clusters = const [],
    this.isEnabled = true,
    this.strategyName,
    this.errorMessage,
    this.selectedCluster,
    this.selectedItem,
    this.categoryFilter,
    this.startTimeFilter,
    this.endTimeFilter,
    this.benchmarkResults,
    this.performanceStats,
    this.availableStrategies = const [],
  });

  /// Create a copy of the state with updated fields
  ClusteringState<T> copyWith({
    ClusteringStatus? status,
    ClusteringParameters? parameters,
    List<T>? items,
    List<Cluster<T>>? clusters,
    bool? isEnabled,
    String? strategyName,
    String? errorMessage,
    Cluster<T>? selectedCluster,
    T? selectedItem,
    String? categoryFilter,
    DateTime? startTimeFilter,
    DateTime? endTimeFilter,
    Map<String, dynamic>? benchmarkResults,
    Map<String, dynamic>? performanceStats,
    List<String>? availableStrategies,
  }) {
    return ClusteringState<T>(
      status: status ?? this.status,
      parameters: parameters ?? this.parameters,
      items: items ?? this.items,
      clusters: clusters ?? this.clusters,
      isEnabled: isEnabled ?? this.isEnabled,
      strategyName: strategyName ?? this.strategyName,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCluster: selectedCluster ?? this.selectedCluster,
      selectedItem: selectedItem ?? this.selectedItem,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      startTimeFilter: startTimeFilter ?? this.startTimeFilter,
      endTimeFilter: endTimeFilter ?? this.endTimeFilter,
      benchmarkResults: benchmarkResults ?? this.benchmarkResults,
      performanceStats: performanceStats ?? this.performanceStats,
      availableStrategies: availableStrategies ?? this.availableStrategies,
    );
  }

  /// Create a copy with cleared selection
  ClusteringState<T> copyWithClearedSelection() {
    return copyWith(
      selectedCluster: null,
      selectedItem: null,
      status: ClusteringStatus.loaded,
    );
  }

  /// Create a copy with error state
  ClusteringState<T> copyWithError(String error) {
    return copyWith(
      status: ClusteringStatus.error,
      errorMessage: error,
    );
  }

  /// Get filtered clusters based on current filters
  List<Cluster<T>> get filteredClusters {
    if (!hasActiveFilters) {
      return clusters;
    }

    return clusters.where((cluster) {
      // Category filter
      if (categoryFilter != null) {
        final hasCategory = cluster.items.any((item) => item.category == categoryFilter);
        if (!hasCategory) return false;
      }

      // Time filter
      if (startTimeFilter != null || endTimeFilter != null) {
        final hasTimeInRange = cluster.items.any((item) {
          final timestamp = item.timestamp;
          if (timestamp == null) return false;

          if (startTimeFilter != null && timestamp.isBefore(startTimeFilter!)) {
            return false;
          }

          if (endTimeFilter != null && timestamp.isAfter(endTimeFilter!)) {
            return false;
          }

          return true;
        });

        if (!hasTimeInRange) return false;
      }

      return true;
    }).toList();
  }

  /// Get individual items from single-item clusters
  List<T> get individualItems {
    return filteredClusters.where((cluster) => cluster.isSingleItem).map((cluster) => cluster.firstItem).toList();
  }

  /// Get multi-item clusters
  List<Cluster<T>> get multiItemClusters {
    return filteredClusters.where((cluster) => !cluster.isSingleItem).toList();
  }

  /// Check if there are active filters
  bool get hasActiveFilters {
    return categoryFilter != null || startTimeFilter != null || endTimeFilter != null;
  }

  /// Get total number of items in all clusters
  int get totalItemsCount {
    return clusters.fold(0, (sum, cluster) => sum + cluster.count);
  }

  /// Get compression ratio (clusters/items)
  double get compressionRatio {
    if (items.isEmpty) return 0.0;
    return clusters.length / items.length;
  }

  /// Get clustering statistics
  Map<String, dynamic> get clusteringStats {
    final filtered = filteredClusters;

    return {
      "totalItems": items.length,
      "totalClusters": clusters.length,
      "filteredClusters": filtered.length,
      "individualItems": individualItems.length,
      "multiItemClusters": multiItemClusters.length,
      "compressionRatio": compressionRatio,
      "isEnabled": isEnabled,
      "strategyName": strategyName,
      "hasActiveFilters": hasActiveFilters,
      "parameters": {
        "zoomLevel": parameters.zoomLevel,
        "minClusterSize": parameters.minClusterSize,
        "maxClusterSize": parameters.maxClusterSize,
        "enableSpatialIndexing": parameters.enableSpatialIndexing,
        "enableIncrementalClustering": parameters.enableIncrementalClustering,
      },
    };
  }

  /// Check if clustering is currently processing
  bool get isProcessing {
    return status == ClusteringStatus.loading || status == ClusteringStatus.benchmarking;
  }

  /// Check if clustering is in error state
  bool get hasError => status == ClusteringStatus.error;

  /// Check if clustering is loaded and ready
  bool get isLoaded => status == ClusteringStatus.loaded;

  /// Check if a cluster is currently selected
  bool get hasSelectedCluster => selectedCluster != null;

  /// Check if an item is currently selected
  bool get hasSelectedItem => selectedItem != null;

  /// Check if benchmark results are available
  bool get hasBenchmarkResults => benchmarkResults != null;

  /// Check if performance stats are available
  bool get hasPerformanceStats => performanceStats != null;

  @override
  List<Object?> get props => [
        status,
        parameters,
        items,
        clusters,
        isEnabled,
        strategyName,
        errorMessage,
        selectedCluster,
        selectedItem,
        categoryFilter,
        startTimeFilter,
        endTimeFilter,
        benchmarkResults,
        performanceStats,
        availableStrategies,
      ];

  @override
  String toString() {
    return "ClusteringState("
        "status: $status, "
        "itemsCount: ${items.length}, "
        "clustersCount: ${clusters.length}, "
        "isEnabled: $isEnabled, "
        "strategyName: $strategyName"
        ")";
  }
}
