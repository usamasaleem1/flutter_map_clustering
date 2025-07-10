import "package:equatable/equatable.dart";
import "package:meta/meta.dart";

/// Configuration parameters for clustering algorithms
@immutable
class ClusteringParameters extends Equatable {
  /// Current zoom level for map-based clustering
  final double zoomLevel;

  /// Maximum distance between items to be clustered (in meters)
  final double? maxClusterDistance;

  /// Minimum number of items required to form a cluster
  final int minClusterSize;

  /// Maximum number of items allowed in a single cluster
  final int? maxClusterSize;

  /// Whether to use incremental clustering for performance
  final bool enableIncrementalClustering;

  /// Whether to use spatial indexing for performance
  final bool enableSpatialIndexing;

  /// Custom parameters for specific clustering strategies
  final Map<String, dynamic> customParameters;

  /// Zoom level threshold for showing individual items
  final double individualItemsZoomThreshold;

  /// Zoom level threshold for maximum clustering
  final double maxClusteringZoomThreshold;

  /// Zoom level threshold for minimum clustering
  final double minClusteringZoomThreshold;

  /// Weight factor for distance calculations
  final double distanceWeightFactor;

  /// Whether to consider timestamps in clustering
  final bool enableTemporalClustering;

  /// Time window for temporal clustering (in minutes)
  final int temporalClusteringWindow;

  /// Whether to cluster by category
  final bool enableCategoryClustering;

  const ClusteringParameters({
    this.zoomLevel = 14.0,
    this.maxClusterDistance,
    this.minClusterSize = 2,
    this.maxClusterSize,
    this.enableIncrementalClustering = true,
    this.enableSpatialIndexing = true,
    this.customParameters = const {},
    this.individualItemsZoomThreshold = 16.0,
    this.maxClusteringZoomThreshold = 16.0,
    this.minClusteringZoomThreshold = 4.0,
    this.distanceWeightFactor = 1.0,
    this.enableTemporalClustering = false,
    this.temporalClusteringWindow = 60,
    this.enableCategoryClustering = false,
  });

  /// Creates a copy of this parameters with the given changes
  ClusteringParameters copyWith({
    double? zoomLevel,
    double? maxClusterDistance,
    int? minClusterSize,
    int? maxClusterSize,
    bool? enableIncrementalClustering,
    bool? enableSpatialIndexing,
    Map<String, dynamic>? customParameters,
    double? individualItemsZoomThreshold,
    double? maxClusteringZoomThreshold,
    double? minClusteringZoomThreshold,
    double? distanceWeightFactor,
    bool? enableTemporalClustering,
    int? temporalClusteringWindow,
    bool? enableCategoryClustering,
  }) {
    return ClusteringParameters(
      zoomLevel: zoomLevel ?? this.zoomLevel,
      maxClusterDistance: maxClusterDistance ?? this.maxClusterDistance,
      minClusterSize: minClusterSize ?? this.minClusterSize,
      maxClusterSize: maxClusterSize ?? this.maxClusterSize,
      enableIncrementalClustering: enableIncrementalClustering ?? this.enableIncrementalClustering,
      enableSpatialIndexing: enableSpatialIndexing ?? this.enableSpatialIndexing,
      customParameters: customParameters ?? this.customParameters,
      individualItemsZoomThreshold: individualItemsZoomThreshold ?? this.individualItemsZoomThreshold,
      maxClusteringZoomThreshold: maxClusteringZoomThreshold ?? this.maxClusteringZoomThreshold,
      minClusteringZoomThreshold: minClusteringZoomThreshold ?? this.minClusteringZoomThreshold,
      distanceWeightFactor: distanceWeightFactor ?? this.distanceWeightFactor,
      enableTemporalClustering: enableTemporalClustering ?? this.enableTemporalClustering,
      temporalClusteringWindow: temporalClusteringWindow ?? this.temporalClusteringWindow,
      enableCategoryClustering: enableCategoryClustering ?? this.enableCategoryClustering,
    );
  }

  /// Calculates the effective cluster distance threshold based on zoom level
  double getEffectiveClusterDistance() {
    if (maxClusterDistance != null) {
      return maxClusterDistance!;
    }

    // Calculate distance threshold based on zoom level
    const maxDistance = 20000.0; // 20km at low zoom
    // const minDistance = 200.0; // 200m at high zoom

    final normalizedZoom =
        (zoomLevel - minClusteringZoomThreshold) / (maxClusteringZoomThreshold - minClusteringZoomThreshold);
    final clampedZoom = normalizedZoom.clamp(0.0, 1.0);

    // Exponential falloff for more natural clustering
    return maxDistance * (1 - clampedZoom * clampedZoom);
  }

  /// Validates the parameters
  bool isValid() {
    return zoomLevel >= 0 &&
        minClusterSize >= 1 &&
        (maxClusterSize == null || maxClusterSize! >= minClusterSize) &&
        individualItemsZoomThreshold >= 0 &&
        maxClusteringZoomThreshold >= minClusteringZoomThreshold &&
        distanceWeightFactor > 0 &&
        temporalClusteringWindow > 0;
  }

  @override
  List<Object?> get props => [
        zoomLevel,
        maxClusterDistance,
        minClusterSize,
        maxClusterSize,
        enableIncrementalClustering,
        enableSpatialIndexing,
        customParameters,
        individualItemsZoomThreshold,
        maxClusteringZoomThreshold,
        minClusteringZoomThreshold,
        distanceWeightFactor,
        enableTemporalClustering,
        temporalClusteringWindow,
        enableCategoryClustering,
      ];
}
