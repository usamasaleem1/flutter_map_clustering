# Flutter Clustering Library

A high-performance clustering library for location-based data with Flutter integration.

## Features

- Multiple clustering algorithms (Distance-based, Density-based, Hierarchical)
- Spatial indexing for performance optimization
- Flutter BLoC integration
- Customizable clustering parameters
- Ready-to-use Flutter widgets

## Installation

```yaml
dependencies:
  flutter_clustering_library: ^1.0.0
```

## Quick Start

```dart
// Create clusterable items
final items = [
  MyClusterableItem(id: '1', location: LatLng(40.7128, -74.0060)),
  MyClusterableItem(id: '2', location: LatLng(40.7589, -73.9851)),
];

// Set up clustering
final repository = ClusteringRepository<MyClusterableItem>();
final parameters = ClusteringParameters(
  zoomLevel: 14.0,
  minClusterSize: 2,
);

// Calculate clusters
final clusters = await repository.calculateClusters(
  items: items,
  parameters: parameters,
);
```


# LICENSE

MIT License

Copyright (c) 2025 Usama Saleem

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
