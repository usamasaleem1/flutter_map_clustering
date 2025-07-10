import "package:flutter_bloc/flutter_bloc.dart";

import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";
import "package:flutter_clustering_library/src/core/interfaces/clustering_logger.dart";
import "package:flutter_clustering_library/src/core/models/cluster.dart";
import "package:flutter_clustering_library/src/clustering/repositories/clustering_repository.dart";
import "package:flutter_clustering_library/src/flutter_integration/blocs/clustering_event.dart";
import "package:flutter_clustering_library/src/flutter_integration/blocs/clustering_state.dart";

/// BLoC for managing clustering operations
class ClusteringBloc<T extends ClusterableItem> extends Bloc<ClusteringEvent, ClusteringState<T>> {
  final ClusteringRepository<T> _repository;
  final ClusteringLogger _logger;

  ClusteringBloc({
    required ClusteringRepository<T> repository,
    ClusteringLogger? logger,
  })  : _repository = repository,
        _logger = logger ?? const NoOpClusteringLogger(),
        super(ClusteringState<T>(
          items: List<T>.empty(),
          clusters: List<Cluster<T>>.empty(),
          availableStrategies: const <String>[],
        )) {
    on<ClusteringInitialized>(_onInitialized);
    on<ClusteringParametersChanged>(_onParametersChanged);
    on<ClusteringItemsUpdated<T>>(_onItemsUpdated);
    on<ClusteringItemsAdded<T>>(_onItemsAdded);
    on<ClusteringItemsRemoved<T>>(_onItemsRemoved);
    on<ClusteringZoomChanged>(_onZoomChanged);
    on<ClusteringClusterTapped<T>>(_onClusterTapped);
    on<ClusteringItemTapped<T>>(_onItemTapped);
    on<ClusteringRefreshRequested>(_onRefreshRequested);
    on<ClusteringStrategyChanged>(_onStrategyChanged);
    on<ClusteringToggled>(_onToggled);
    on<ClusteringClusterExpanded<T>>(_onClusterExpanded);
    on<ClusteringFilterChanged>(_onFilterChanged);
    on<ClusteringBenchmarkRequested>(_onBenchmarkRequested);
    on<ClusteringCleared>(_onCleared);
  }

  Future<void> _onInitialized(
    ClusteringInitialized event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      _logger.info("Clustering initialized");

      emit(state.copyWith(
        status: ClusteringStatus.loaded,
        isEnabled: true,
        availableStrategies: _repository.availableStrategies,
      ));
    } catch (e) {
      _logger.error("Error initializing clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onParametersChanged(
    ClusteringParametersChanged event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      if (state.parameters == event.parameters) return;

      emit(state.copyWith(
        parameters: event.parameters,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error updating clustering parameters", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onItemsUpdated(
    ClusteringItemsUpdated<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      if (state.items == event.items) return;

      emit(state.copyWith(
        items: event.items,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error updating clustering items", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onItemsAdded(
    ClusteringItemsAdded<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      final newItems = [...state.items, ...event.items];

      emit(state.copyWith(
        items: newItems,
        status: ClusteringStatus.loading,
      ));

      if (state.parameters.enableIncrementalClustering) {
        await _performIncrementalClustering(event.items, emit);
      } else {
        await _recalculateClusters(emit);
      }
    } catch (e) {
      _logger.error("Error adding items to clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onItemsRemoved(
    ClusteringItemsRemoved<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      final removedIds = event.items.map((item) => item.id).toSet();
      final remainingItems = state.items.where((item) => !removedIds.contains(item.id)).toList();

      emit(state.copyWith(
        items: remainingItems,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error removing items from clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onZoomChanged(
    ClusteringZoomChanged event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      if (state.parameters.zoomLevel == event.zoomLevel) return;

      final newParameters = state.parameters.copyWith(zoomLevel: event.zoomLevel);

      emit(state.copyWith(
        parameters: newParameters,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error changing zoom level", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onClusterTapped(
    ClusteringClusterTapped<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      _logger.info("Cluster tapped: ${event.cluster.id} with ${event.cluster.count} items");

      emit(state.copyWith(
        selectedCluster: event.cluster,
        status: ClusteringStatus.clusterTapped,
      ));

      // Reset status after handling
      emit(state.copyWith(status: ClusteringStatus.loaded));
    } catch (e) {
      _logger.error("Error handling cluster tap", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onItemTapped(
    ClusteringItemTapped<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      _logger.info("Item tapped: ${event.item.id}");

      emit(state.copyWith(
        selectedItem: event.item,
        status: ClusteringStatus.itemTapped,
      ));

      // Reset status after handling
      emit(state.copyWith(status: ClusteringStatus.loaded));
    } catch (e) {
      _logger.error("Error handling item tap", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onRefreshRequested(
    ClusteringRefreshRequested event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      emit(state.copyWith(status: ClusteringStatus.loading));
      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error refreshing clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onStrategyChanged(
    ClusteringStrategyChanged event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      _repository.setStrategy(event.strategyName);

      emit(state.copyWith(
        strategyName: event.strategyName,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error changing clustering strategy", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onToggled(
    ClusteringToggled event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      emit(state.copyWith(
        isEnabled: event.enabled,
        status: event.enabled ? ClusteringStatus.loading : ClusteringStatus.loaded,
      ));

      if (event.enabled) {
        await _recalculateClusters(emit);
      } else {
        emit(state.copyWith(
          clusters: const [],
          status: ClusteringStatus.loaded,
        ));
      }
    } catch (e) {
      _logger.error("Error toggling clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onClusterExpanded(
    ClusteringClusterExpanded<T> event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      final updatedClusters = state.clusters.map((cluster) {
        if (cluster.id == event.cluster.id) {
          return cluster.copyWith(isExpanded: event.expanded);
        }
        return cluster;
      }).toList();

      emit(state.copyWith(clusters: updatedClusters));
    } catch (e) {
      _logger.error("Error expanding/collapsing cluster", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    ClusteringFilterChanged event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      emit(state.copyWith(
        categoryFilter: event.category,
        startTimeFilter: event.startTime,
        endTimeFilter: event.endTime,
        status: ClusteringStatus.loading,
      ));

      await _recalculateClusters(emit);
    } catch (e) {
      _logger.error("Error applying filter", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onBenchmarkRequested(
    ClusteringBenchmarkRequested event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      emit(state.copyWith(status: ClusteringStatus.benchmarking));

      final strategies = event.strategyNames ?? _repository.availableStrategies;
      final benchmarkResults = <String, Map<String, dynamic>>{};

      for (final strategyName in strategies) {
        final stopwatch = Stopwatch()..start();

        try {
          final clusters = await _repository.calculateClustersWithStrategy(
            items: state.items,
            parameters: state.parameters,
            strategyName: strategyName,
          );

          stopwatch.stop();

          benchmarkResults[strategyName] = {
            "duration": stopwatch.elapsedMilliseconds,
            "clusterCount": clusters.length,
            "success": true,
          };
        } catch (e) {
          stopwatch.stop();
          benchmarkResults[strategyName] = {
            "duration": stopwatch.elapsedMilliseconds,
            "error": e.toString(),
            "success": false,
          };
        }
      }

      emit(state.copyWith(
        benchmarkResults: benchmarkResults,
        status: ClusteringStatus.benchmarkCompleted,
      ));

      // Reset to normal state
      emit(state.copyWith(status: ClusteringStatus.loaded));
    } catch (e) {
      _logger.error("Error running benchmark", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onCleared(
    ClusteringCleared event,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      emit(state.copyWith(
        items: const [],
        clusters: const [],
        selectedCluster: null,
        selectedItem: null,
        status: ClusteringStatus.loaded,
      ));
    } catch (e) {
      _logger.error("Error clearing clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _recalculateClusters(Emitter<ClusteringState<T>> emit) async {
    if (!state.isEnabled || state.items.isEmpty) {
      emit(state.copyWith(
        clusters: const [],
        status: ClusteringStatus.loaded,
      ));
      return;
    }

    try {
      final stopwatch = Stopwatch()..start();

      final filteredItems = _applyFilters(state.items);
      final clusters = await _repository.calculateClusters(
        items: filteredItems,
        parameters: state.parameters,
      );

      stopwatch.stop();

      emit(state.copyWith(
        clusters: clusters,
        status: ClusteringStatus.loaded,
        performanceStats: _calculateStatistics(clusters, filteredItems, stopwatch.elapsedMilliseconds),
      ));
    } catch (e) {
      _logger.error("Error recalculating clusters", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _performIncrementalClustering(
    List<T> newItems,
    Emitter<ClusteringState<T>> emit,
  ) async {
    try {
      // Simple incremental clustering - could be optimized further
      final allItems = [...state.items];
      final clusters = await _repository.calculateClusters(
        items: allItems,
        parameters: state.parameters,
      );

      emit(state.copyWith(
        clusters: clusters,
        status: ClusteringStatus.loaded,
        performanceStats: _calculateStatistics(clusters, allItems, 0),
      ));
    } catch (e) {
      _logger.error("Error performing incremental clustering", e);
      emit(state.copyWithError(e.toString()));
    }
  }

  List<T> _applyFilters(List<T> items) {
    var filteredItems = items;

    if (state.categoryFilter != null) {
      filteredItems = filteredItems.where((item) => item.category == state.categoryFilter).toList();
    }

    if (state.startTimeFilter != null || state.endTimeFilter != null) {
      filteredItems = filteredItems.where((item) {
        final timestamp = item.timestamp;
        if (timestamp == null) return false;

        if (state.startTimeFilter != null && timestamp.isBefore(state.startTimeFilter!)) {
          return false;
        }

        if (state.endTimeFilter != null && timestamp.isAfter(state.endTimeFilter!)) {
          return false;
        }

        return true;
      }).toList();
    }

    return filteredItems;
  }

  Map<String, dynamic> _calculateStatistics(List<Cluster<T>> clusters, List<T> items, int calculationTime) {
    if (clusters.isEmpty) {
      return {
        "totalItems": items.length,
        "totalClusters": 0,
        "averageClusterSize": 0.0,
        "largestClusterSize": 0,
        "smallestClusterSize": 0,
        "singleItemClusters": 0,
        "calculationTime": calculationTime,
      };
    }

    final clusterSizes = clusters.map((cluster) => cluster.count).toList();
    final singleItemClusters = clusters.where((cluster) => cluster.isSingleItem).length;

    return {
      "totalItems": items.length,
      "totalClusters": clusters.length,
      "averageClusterSize": clusterSizes.reduce((a, b) => a + b) / clusters.length,
      "largestClusterSize": clusterSizes.reduce((a, b) => a > b ? a : b),
      "smallestClusterSize": clusterSizes.reduce((a, b) => a < b ? a : b),
      "singleItemClusters": singleItemClusters,
      "calculationTime": calculationTime,
    };
  }

  @override
  Future<void> close() {
    _logger.info("Clustering BLoC closed");
    return super.close();
  }
}
