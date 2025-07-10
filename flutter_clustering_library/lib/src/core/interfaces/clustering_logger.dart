/// Interface for logging within the clustering library
abstract class ClusteringLogger {
  /// Log debug messages
  void debug(String message, [Object? error, StackTrace? stackTrace]);

  /// Log info messages
  void info(String message, [Object? error, StackTrace? stackTrace]);

  /// Log warning messages
  void warning(String message, [Object? error, StackTrace? stackTrace]);

  /// Log error messages
  void error(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default no-op logger implementation
class NoOpClusteringLogger implements ClusteringLogger {
  const NoOpClusteringLogger();

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {}

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {}
}

/// Simple print-based logger for debugging
class PrintClusteringLogger implements ClusteringLogger {
  const PrintClusteringLogger();

  @override
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    print('[DEBUG] $message${error != null ? ' - $error' : ''}');
  }

  @override
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    print('[INFO] $message${error != null ? ' - $error' : ''}');
  }

  @override
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    print('[WARNING] $message${error != null ? ' - $error' : ''}');
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('[ERROR] $message${error != null ? ' - $error' : ''}');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }
}
