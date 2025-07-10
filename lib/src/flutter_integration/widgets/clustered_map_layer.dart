import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster.dart";
import "package:flutter_map_clustering/src/flutter_integration/widgets/cluster_marker.dart";

/// A map layer that displays clustered items
class ClusteredMapLayer<T extends ClusterableItem> extends StatelessWidget {
  final List<Cluster<T>> clusters;
  final Function(Cluster<T>)? onClusterTap;
  final Function(T)? onItemTap;
  final String? selectedClusterId;
  final String? selectedItemId;
  final double markerSize;
  final Widget Function(Cluster<T>)? customClusterBuilder;
  final Widget Function(T)? customItemBuilder;

  const ClusteredMapLayer({
    required this.clusters,
    this.onClusterTap,
    this.onItemTap,
    this.selectedClusterId,
    this.selectedItemId,
    this.markerSize = 40.0,
    this.customClusterBuilder,
    this.customItemBuilder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        ..._buildClusterMarkers(),
        ..._buildItemMarkers(),
      ],
    );
  }

  List<Marker> _buildClusterMarkers() {
    return clusters.where((cluster) => !cluster.isSingleItem).map((cluster) {
      return Marker(
        point: cluster.center,
        width: markerSize,
        height: markerSize,
        alignment: Alignment.center,
        child: customClusterBuilder?.call(cluster) ??
            ClusterMarker<T>(
              cluster: cluster,
              onTap: () => onClusterTap?.call(cluster),
              isSelected: cluster.id == selectedClusterId,
              size: markerSize,
            ),
      );
    }).toList();
  }

  List<Marker> _buildItemMarkers() {
    return clusters.where((cluster) => cluster.isSingleItem).map((cluster) {
      final item = cluster.firstItem;
      return Marker(
        point: item.location,
        width: markerSize * 0.8,
        height: markerSize * 0.8,
        alignment: Alignment.center,
        child: customItemBuilder?.call(item) ??
            ItemMarker<T>(
              item: item,
              onTap: () => onItemTap?.call(item),
              isSelected: item.id == selectedItemId,
              size: markerSize * 0.8,
            ),
      );
    }).toList();
  }
}

/// A widget that combines cluster display with map interaction
class ClusteredMap<T extends ClusterableItem> extends StatefulWidget {
  final List<Cluster<T>> clusters;
  final Function(Cluster<T>)? onClusterTap;
  final Function(T)? onItemTap;
  final MapController? mapController;
  final String? selectedClusterId;
  final String? selectedItemId;
  final double markerSize;
  final Widget Function(Cluster<T>)? customClusterBuilder;
  final Widget Function(T)? customItemBuilder;
  final List<Widget> additionalLayers;

  const ClusteredMap({
    required this.clusters,
    this.onClusterTap,
    this.onItemTap,
    this.mapController,
    this.selectedClusterId,
    this.selectedItemId,
    this.markerSize = 40.0,
    this.customClusterBuilder,
    this.customItemBuilder,
    this.additionalLayers = const [],
    super.key,
  });

  @override
  State<ClusteredMap<T>> createState() => _ClusteredMapState<T>();
}

class _ClusteredMapState<T extends ClusterableItem> extends State<ClusteredMap<T>> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialZoom: 10.0,
        minZoom: 3.0,
        maxZoom: 18.0,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "flutter_map_clustering",
        ),
        ...widget.additionalLayers,
        ClusteredMapLayer<T>(
          clusters: widget.clusters,
          onClusterTap: widget.onClusterTap,
          onItemTap: widget.onItemTap,
          selectedClusterId: widget.selectedClusterId,
          selectedItemId: widget.selectedItemId,
          markerSize: widget.markerSize,
          customClusterBuilder: widget.customClusterBuilder,
          customItemBuilder: widget.customItemBuilder,
        ),
      ],
    );
  }
}
