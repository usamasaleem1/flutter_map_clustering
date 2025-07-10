import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";

import "package:flutter_clustering_library/src/core/interfaces/clusterable_item.dart";
import "package:flutter_clustering_library/src/core/models/cluster.dart";

/// A generic cluster marker widget for displaying clusters on the map
class ClusterMarker<T extends ClusterableItem> extends StatelessWidget {
  final Cluster<T> cluster;
  final VoidCallback? onTap;
  final bool isSelected;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? icon;

  const ClusterMarker({
    required this.cluster,
    this.onTap,
    this.isSelected = false,
    this.size = 40.0,
    this.backgroundColor,
    this.textColor,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? _getBackgroundColor(theme);
    final effectiveTextColor = textColor ?? _getTextColor(theme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: cluster.isSingleItem
              ? (icon ?? Icon(Icons.place, color: effectiveTextColor, size: size * 0.6))
              : Text(
                  cluster.count.toString(),
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (cluster.isSingleItem) {
      return theme.colorScheme.primary;
    }

    final count = cluster.count;
    if (count <= 10) return Colors.green;
    if (count <= 50) return Colors.orange;
    if (count <= 100) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getTextColor(ThemeData theme) {
    return Colors.white;
  }
}

/// A simple marker widget for individual items
class ItemMarker<T extends ClusterableItem> extends StatelessWidget {
  final T item;
  final VoidCallback? onTap;
  final bool isSelected;
  final double size;
  final Color? backgroundColor;
  final Widget? icon;

  const ItemMarker({
    required this.item,
    this.onTap,
    this.isSelected = false,
    this.size = 36.0,
    this.backgroundColor,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(
                  color: theme.colorScheme.primary,
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon ??
              Icon(
                Icons.place,
                color: Colors.white,
                size: size * 0.6,
              ),
        ),
      ),
    );
  }
}
