import "package:latlong2/latlong.dart" hide Distance, DistanceCalculator;

import "package:flutter_map_clustering/src/core/interfaces/clusterable_item.dart";
import "package:flutter_map_clustering/src/core/models/cluster_bounds.dart";
import "package:flutter_map_clustering/src/core/utils/distance_calculator.dart";
import "package:flutter_map_clustering/src/spatial_indexing/spatial_index.dart";

/// QuadTree implementation for efficient spatial indexing
class QuadTreeSpatialIndex<T extends ClusterableItem> implements SpatialIndex<T> {
  final _QuadTreeNode<T> _root;
  final int _maxItemsPerNode;
  final int _maxDepth;
  int _size = 0;

  QuadTreeSpatialIndex({
    required ClusterBounds bounds,
    int maxItemsPerNode = 10,
    int maxDepth = 8,
  })  : _root = _QuadTreeNode<T>(bounds, 0),
        _maxItemsPerNode = maxItemsPerNode,
        _maxDepth = maxDepth;

  @override
  void insert(T item) {
    if (_root.insert(item, _maxItemsPerNode, _maxDepth)) {
      _size++;
    }
  }

  @override
  bool remove(T item) {
    if (_root.remove(item)) {
      _size--;
      return true;
    }
    return false;
  }

  @override
  void update(T item) {
    remove(item);
    insert(item);
  }

  @override
  void clear() {
    _root.clear();
    _size = 0;
  }

  @override
  List<T> findNearby(LatLng point, double radiusMeters) {
    final searchBounds = ClusterBounds.fromPointWithRadius(point, radiusMeters);
    final candidates = _root.findInBounds(searchBounds);

    return candidates.where((item) {
      final distance = DistanceCalculator.calculateDistance(point, item.location);
      return distance <= radiusMeters;
    }).toList();
  }

  @override
  List<T> findInBounds(ClusterBounds bounds) {
    return _root.findInBounds(bounds);
  }

  @override
  List<T> getAllItems() {
    return _root.getAllItems();
  }

  @override
  int get size => _size;

  @override
  bool get isEmpty => _size == 0;

  @override
  bool contains(T item) {
    return _root.contains(item);
  }

  @override
  ClusterBounds? getBounds() {
    if (isEmpty) return null;
    return _root.bounds;
  }

  @override
  T? findNearestNeighbor(LatLng point) {
    final neighbors = findKNearestNeighbors(point, 1);
    return neighbors.isEmpty ? null : neighbors.first;
  }

  @override
  List<T> findKNearestNeighbors(LatLng point, int k) {
    final allItems = getAllItems();
    if (allItems.isEmpty) return [];

    // Sort by distance and take the first k
    allItems.sort((a, b) {
      final distanceA = DistanceCalculator.calculateDistance(point, a.location);
      final distanceB = DistanceCalculator.calculateDistance(point, b.location);
      return distanceA.compareTo(distanceB);
    });

    return allItems.take(k).toList();
  }

  @override
  void insertAll(List<T> items) {
    for (final item in items) {
      insert(item);
    }
  }

  @override
  void removeAll(List<T> items) {
    for (final item in items) {
      remove(item);
    }
  }

  @override
  void optimize() {
    // QuadTree doesn't need explicit optimization
    // It's automatically balanced during insertion
  }
}

/// Internal node class for the QuadTree
class _QuadTreeNode<T extends ClusterableItem> {
  final ClusterBounds bounds;
  final int depth;
  final List<T> items = [];

  _QuadTreeNode<T>? _northWest;
  _QuadTreeNode<T>? _northEast;
  _QuadTreeNode<T>? _southWest;
  _QuadTreeNode<T>? _southEast;

  _QuadTreeNode(this.bounds, this.depth);

  bool get isLeaf => _northWest == null;

  bool insert(T item, int maxItemsPerNode, int maxDepth) {
    if (!bounds.contains(item.location)) {
      return false;
    }

    if (isLeaf) {
      if (items.length < maxItemsPerNode || depth >= maxDepth) {
        if (!items.any((existingItem) => existingItem.id == item.id)) {
          items.add(item);
          return true;
        }
        return false;
      }

      // Split the node
      _split();

      // Redistribute existing items
      final itemsToRedistribute = List<T>.from(items);
      items.clear();

      for (final existingItem in itemsToRedistribute) {
        _insertIntoChild(existingItem);
      }

      return _insertIntoChild(item);
    } else {
      return _insertIntoChild(item);
    }
  }

  bool _insertIntoChild(T item) {
    if (_northWest!.insert(item, 10, 8)) return true;
    if (_northEast!.insert(item, 10, 8)) return true;
    if (_southWest!.insert(item, 10, 8)) return true;
    if (_southEast!.insert(item, 10, 8)) return true;
    return false;
  }

  bool remove(T item) {
    if (!bounds.contains(item.location)) {
      return false;
    }

    if (isLeaf) {
      final originalLength = items.length;
      items.removeWhere((existingItem) => existingItem.id == item.id);
      return items.length < originalLength;
    } else {
      return _northWest!.remove(item) ||
          _northEast!.remove(item) ||
          _southWest!.remove(item) ||
          _southEast!.remove(item);
    }
  }

  bool contains(T item) {
    if (!bounds.contains(item.location)) {
      return false;
    }

    if (isLeaf) {
      return items.any((existingItem) => existingItem.id == item.id);
    } else {
      return _northWest!.contains(item) ||
          _northEast!.contains(item) ||
          _southWest!.contains(item) ||
          _southEast!.contains(item);
    }
  }

  List<T> findInBounds(ClusterBounds searchBounds) {
    final result = <T>[];

    if (!bounds.intersects(searchBounds)) {
      return result;
    }

    if (isLeaf) {
      for (final item in items) {
        if (searchBounds.contains(item.location)) {
          result.add(item);
        }
      }
    } else {
      result.addAll(_northWest!.findInBounds(searchBounds));
      result.addAll(_northEast!.findInBounds(searchBounds));
      result.addAll(_southWest!.findInBounds(searchBounds));
      result.addAll(_southEast!.findInBounds(searchBounds));
    }

    return result;
  }

  List<T> getAllItems() {
    final result = <T>[];

    if (isLeaf) {
      result.addAll(items);
    } else {
      result.addAll(_northWest!.getAllItems());
      result.addAll(_northEast!.getAllItems());
      result.addAll(_southWest!.getAllItems());
      result.addAll(_southEast!.getAllItems());
    }

    return result;
  }

  void clear() {
    items.clear();
    _northWest = null;
    _northEast = null;
    _southWest = null;
    _southEast = null;
  }

  void _split() {
    final centerLat = (bounds.northEast.latitude + bounds.southWest.latitude) / 2;
    final centerLng = (bounds.northEast.longitude + bounds.southWest.longitude) / 2;

    _northWest = _QuadTreeNode<T>(
      ClusterBounds(
        northEast: bounds.northEast,
        southWest: LatLng(centerLat, bounds.southWest.longitude),
      ),
      depth + 1,
    );

    _northEast = _QuadTreeNode<T>(
      ClusterBounds(
        northEast: bounds.northEast,
        southWest: LatLng(centerLat, centerLng),
      ),
      depth + 1,
    );

    _southWest = _QuadTreeNode<T>(
      ClusterBounds(
        northEast: LatLng(centerLat, centerLng),
        southWest: bounds.southWest,
      ),
      depth + 1,
    );

    _southEast = _QuadTreeNode<T>(
      ClusterBounds(
        northEast: LatLng(centerLat, bounds.northEast.longitude),
        southWest: LatLng(bounds.southWest.latitude, centerLng),
      ),
      depth + 1,
    );
  }
}
