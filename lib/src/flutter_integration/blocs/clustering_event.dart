import "package:equatable/equatable.dart";

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/core/models/clustering_parameters.dart";

/// Base class for clustering events
abstract class ClusteringEvent extends Equatable {
  const ClusteringEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize clustering
class ClusteringInitialized extends ClusteringEvent {
  const ClusteringInitialized();
}

/// Event to update clustering parameters
class ClusteringParametersChanged extends ClusteringEvent {
  final ClusteringParameters parameters;

  const ClusteringParametersChanged(this.parameters);

  @override
  List<Object?> get props => [parameters];
}

/// Event to update the list of items to cluster
class ClusteringItemsUpdated<T extends ClusterableItem> extends ClusteringEvent {
  final List<T> items;

  const ClusteringItemsUpdated(this.items);

  @override
  List<Object?> get props => [items];
}

/// Event to add new items for incremental clustering
class ClusteringItemsAdded<T extends ClusterableItem> extends ClusteringEvent {
  final List<T> items;

  const ClusteringItemsAdded(this.items);

  @override
  List<Object?> get props => [items];
}

/// Event to remove items from clustering
class ClusteringItemsRemoved<T extends ClusterableItem> extends ClusteringEvent {
  final List<T> items;

  const ClusteringItemsRemoved(this.items);

  @override
  List<Object?> get props => [items];
}

/// Event to change zoom level
class ClusteringZoomChanged extends ClusteringEvent {
  final double zoomLevel;

  const ClusteringZoomChanged(this.zoomLevel);

  @override
  List<Object?> get props => [zoomLevel];
}

/// Event when a cluster is tapped
class ClusteringClusterTapped<T extends ClusterableItem> extends ClusteringEvent {
  final Cluster<T> cluster;

  const ClusteringClusterTapped(this.cluster);

  @override
  List<Object?> get props => [cluster];
}

/// Event when an individual item is tapped
class ClusteringItemTapped<T extends ClusterableItem> extends ClusteringEvent {
  final T item;

  const ClusteringItemTapped(this.item);

  @override
  List<Object?> get props => [item];
}

/// Event to refresh clustering
class ClusteringRefreshRequested extends ClusteringEvent {
  const ClusteringRefreshRequested();
}

/// Event to change clustering strategy
class ClusteringStrategyChanged extends ClusteringEvent {
  final String strategyName;

  const ClusteringStrategyChanged(this.strategyName);

  @override
  List<Object?> get props => [strategyName];
}

/// Event to enable/disable clustering
class ClusteringToggled extends ClusteringEvent {
  final bool enabled;

  const ClusteringToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Event to expand/collapse a cluster
class ClusteringClusterExpanded<T extends ClusterableItem> extends ClusteringEvent {
  final Cluster<T> cluster;
  final bool expanded;

  const ClusteringClusterExpanded(this.cluster, this.expanded);

  @override
  List<Object?> get props => [cluster, expanded];
}

/// Event to filter clusters by criteria
class ClusteringFilterChanged extends ClusteringEvent {
  final String? category;
  final DateTime? startTime;
  final DateTime? endTime;

  const ClusteringFilterChanged({
    this.category,
    this.startTime,
    this.endTime,
  });

  @override
  List<Object?> get props => [category, startTime, endTime];
}

/// Event to benchmark clustering strategies
class ClusteringBenchmarkRequested extends ClusteringEvent {
  final List<String>? strategyNames;

  const ClusteringBenchmarkRequested({this.strategyNames});

  @override
  List<Object?> get props => [strategyNames];
}

/// Event to clear all clusters
class ClusteringCleared extends ClusteringEvent {
  const ClusteringCleared();
}
