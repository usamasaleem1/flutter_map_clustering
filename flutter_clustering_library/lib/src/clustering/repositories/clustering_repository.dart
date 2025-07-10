import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";
import "package:flutter_clustering_library/src/core/interfaces/clustering_logger.dart";
import "package:flutter_clustering_library/src/core/interfaces/clustering_strategy.dart";
import "package:flutter_clustering_library/src/core/models/cluster.dart";
import "package:flutter_clustering_library/src/core/models/clustering_parameters.dart";
import "package:flutter_clustering_library/src/clustering/algorithms/distance_clustering_strategy.dart";

/// Repository for managing clustering operations with different strategies
class ClusteringRepository<T extends ClusterableItem> {
  final ClusteringLogger _logger;
  final Map<String, ClusteringStrategy<T>> _strategies = {};
  ClusteringStrategy<T>? _currentStrategy;

  ClusteringRepository({
    ClusteringLogger? logger,
  }) : _logger = logger ?? const NoOpClusteringLogger() {
    _initializeDefaultStrategies();
  }

  /// Initialize default clustering strategies
  void _initializeDefaultStrategies() {
    final distanceStrategy = DistanceClusteringStrategy<T>(logger: _logger);
    _strategies[distanceStrategy.name] = distanceStrategy;
    _currentStrategy = distanceStrategy;
  }

  /// Register a custom clustering strategy
  void registerStrategy(ClusteringStrategy<T> strategy) {
    _strategies[strategy.name] = strategy;
    _logger.info("Registered clustering strategy: ${strategy.name}");
  }

  /// Set the active clustering strategy
  void setStrategy(String strategyName) {
    final strategy = _strategies[strategyName];
    if (strategy == null) {
      throw ArgumentError("Unknown clustering strategy: $strategyName");
    }
    _currentStrategy = strategy;
    _logger.info("Set active clustering strategy: $strategyName");
  }

  /// Get the current clustering strategy
  ClusteringStrategy<T>? get currentStrategy => _currentStrategy;

  /// Get all available strategy names
  List<String> get availableStrategies => _strategies.keys.toList();

  /// Get strategy by name
  ClusteringStrategy<T>? getStrategy(String name) => _strategies[name];

  /// Calculate clusters using the current strategy
  Future<List<Cluster<T>>> calculateClusters({
    required List<T> items,
    required ClusteringParameters parameters,
  }) async {
    if (_currentStrategy == null) {
      throw StateError("No clustering strategy is set");
    }

    if (!_currentStrategy!.validateParameters(parameters)) {
      throw ArgumentError("Invalid clustering parameters for strategy ${_currentStrategy!.name}");
    }

    _logger.info("Calculating clusters using strategy: ${_currentStrategy!.name}");

    final stopwatch = Stopwatch()..start();

    try {
      final clusters = await _currentStrategy!.calculateClusters(
        items: items,
        parameters: parameters,
      );

      stopwatch.stop();
      _logger.info("Clustering completed in ${stopwatch.elapsedMilliseconds}ms. "
          "Generated ${clusters.length} clusters from ${items.length} items");

      return clusters;
    } catch (e) {
      stopwatch.stop();
      _logger.error("Clustering failed after ${stopwatch.elapsedMilliseconds}ms", e);
      rethrow;
    }
  }

  /// Calculate clusters using a specific strategy
  Future<List<Cluster<T>>> calculateClustersWithStrategy({
    required List<T> items,
    required ClusteringParameters parameters,
    required String strategyName,
  }) async {
    final strategy = _strategies[strategyName];
    if (strategy == null) {
      throw ArgumentError("Unknown clustering strategy: $strategyName");
    }

    if (!strategy.validateParameters(parameters)) {
      throw ArgumentError("Invalid clustering parameters for strategy $strategyName");
    }

    _logger.info("Calculating clusters using strategy: $strategyName");

    final stopwatch = Stopwatch()..start();

    try {
      final clusters = await strategy.calculateClusters(
        items: items,
        parameters: parameters,
      );

      stopwatch.stop();
      _logger.info("Clustering with $strategyName completed in ${stopwatch.elapsedMilliseconds}ms. "
          "Generated ${clusters.length} clusters from ${items.length} items");

      return clusters;
    } catch (e) {
      stopwatch.stop();
      _logger.error("Clustering with $strategyName failed after ${stopwatch.elapsedMilliseconds}ms", e);
      rethrow;
    }
  }

  /// Check if two items should be clustered together
  bool shouldClusterItems(T item1, T item2, ClusteringParameters parameters) {
    if (_currentStrategy == null) {
      throw StateError("No clustering strategy is set");
    }

    return _currentStrategy!.shouldClusterItems(item1, item2, parameters);
  }

  /// Get the cluster distance threshold for the current strategy
  double getClusterDistanceThreshold(ClusteringParameters parameters) {
    if (_currentStrategy == null) {
      throw StateError("No clustering strategy is set");
    }

    return _currentStrategy!.getClusterDistanceThreshold(parameters);
  }

  /// Validate parameters for the current strategy
  bool validateParameters(ClusteringParameters parameters) {
    if (_currentStrategy == null) {
      throw StateError("No clustering strategy is set");
    }

    return _currentStrategy!.validateParameters(parameters);
  }

  /// Get supported parameters for the current strategy
  Set<String> getSupportedParameters() {
    if (_currentStrategy == null) {
      throw StateError("No clustering strategy is set");
    }

    return _currentStrategy!.supportedParameters;
  }

  /// Compare performance of different strategies
  Future<Map<String, dynamic>> benchmarkStrategies({
    required List<T> items,
    required ClusteringParameters parameters,
    List<String>? strategyNames,
  }) async {
    final strategiesToBenchmark = strategyNames ?? availableStrategies;
    final results = <String, dynamic>{};

    _logger.info("Benchmarking ${strategiesToBenchmark.length} strategies with ${items.length} items");

    for (final strategyName in strategiesToBenchmark) {
      final strategy = _strategies[strategyName];
      if (strategy == null) {
        _logger.warning("Strategy $strategyName not found, skipping benchmark");
        continue;
      }

      if (!strategy.validateParameters(parameters)) {
        _logger.warning("Invalid parameters for strategy $strategyName, skipping benchmark");
        continue;
      }

      final stopwatch = Stopwatch()..start();

      try {
        final clusters = await strategy.calculateClusters(
          items: items,
          parameters: parameters,
        );

        stopwatch.stop();

        results[strategyName] = {
          "success": true,
          "processingTimeMs": stopwatch.elapsedMilliseconds,
          "clusterCount": clusters.length,
          "itemCount": items.length,
          "compressionRatio": clusters.length / items.length,
          "averageClusterSize": clusters.fold(0, (sum, cluster) => sum + cluster.count) / clusters.length,
        };

        _logger.info("Strategy $strategyName: ${stopwatch.elapsedMilliseconds}ms, "
            "${clusters.length} clusters");
      } catch (e) {
        stopwatch.stop();
        results[strategyName] = {
          "success": false,
          "error": e.toString(),
          "processingTimeMs": stopwatch.elapsedMilliseconds,
        };
        _logger.error("Strategy $strategyName failed", e);
      }
    }

    return results;
  }

  /// Get recommendations for optimal clustering parameters
  ClusteringParameters getOptimalParameters({
    required List<T> items,
    required double zoomLevel,
    String? strategyName,
  }) {
    final strategy = strategyName != null ? _strategies[strategyName] : _currentStrategy;
    if (strategy == null) {
      throw StateError("No clustering strategy available");
    }

    // Basic optimization based on data characteristics
    if (items.isEmpty) {
      return ClusteringParameters(zoomLevel: zoomLevel);
    }

    final itemCount = items.length;
    final enableSpatialIndexing = itemCount > 100;
    final enableIncrementalClustering = itemCount > 50;

    int minClusterSize = 2;
    if (itemCount > 1000) {
      minClusterSize = 3;
    } else if (itemCount > 10000) {
      minClusterSize = 5;
    }

    return ClusteringParameters(
      zoomLevel: zoomLevel,
      minClusterSize: minClusterSize,
      enableSpatialIndexing: enableSpatialIndexing,
      enableIncrementalClustering: enableIncrementalClustering,
      maxClusterSize: itemCount > 1000 ? 50 : null,
    );
  }

  /// Get clustering statistics for monitoring
  Map<String, dynamic> getClusteringStats() {
    return {
      "currentStrategy": _currentStrategy?.name,
      "availableStrategies": availableStrategies,
      "supportedParameters": _currentStrategy?.supportedParameters.toList(),
    };
  }
}
