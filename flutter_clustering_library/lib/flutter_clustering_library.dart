/// A high-performance clustering library for location-based data with Flutter integration
library flutter_clustering_library;

export "src/clustering/algorithms/density_clustering_strategy.dart";
// Clustering algorithms
export "src/clustering/algorithms/distance_clustering_strategy.dart";
export "src/clustering/algorithms/hierarchical_clustering_strategy.dart";
// Clustering repository
export "src/clustering/repositories/clustering_repository.dart";
// Core interfaces
export "src/core/interfaces/clusterable_item.dart";
export "src/core/interfaces/clustering_logger.dart";
export "src/core/interfaces/clustering_strategy.dart";
// Core models
export "src/core/models/cluster.dart";
export "src/core/models/cluster_bounds.dart";
export "src/core/models/clustering_parameters.dart";
export "src/core/utils/clustering_utils.dart";
// Utilities
export "src/core/utils/distance_calculator.dart";
export "src/flutter_integration/blocs/clustering_bloc.dart";
export "src/flutter_integration/blocs/clustering_event.dart";
export "src/flutter_integration/blocs/clustering_state.dart";
// Flutter integration
export "src/flutter_integration/widgets/cluster_marker.dart";
export "src/flutter_integration/widgets/clustered_map_layer.dart";
export "src/spatial_indexing/quadtree_spatial_index.dart";
// Spatial indexing
export "src/spatial_indexing/spatial_index.dart";
