import 'package:flutter/foundation.dart';

enum OperationName {
  calendar_load_tasks,
  load_calendar_task_view,
  rrule_habit_processing,
}

/// Performance monitoring utility to track and log performance metrics
class PerformanceMonitor {
  static final Map<OperationName, DateTime> _startTimes = {};
  static final Map<OperationName, List<int>> _durations = {};
  static const int _maxSamples = 100;
  static bool _enabled = false; // 控制是否启用性能监控

  /// Enable or disable performance monitoring
  static void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Check if performance monitoring is enabled
  static bool get isEnabled => _enabled;

  /// Start timing an operation
  static void startTimer(OperationName operationName) {
    if (!_enabled) return;
    _startTimes[operationName] = DateTime.now();
  }

  /// End timing an operation and log the duration
  static void endTimer(OperationName operationName) {
    if (!_enabled) return;

    final startTime = _startTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint(
          'PerformanceMonitor: No start time found for $operationName',
        );
      }
      return;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _startTimes.remove(operationName);

    // Store duration for statistics
    _durations.putIfAbsent(operationName, () => <int>[]);
    final durations = _durations[operationName]!;
    durations.add(duration);

    // Keep only the most recent samples
    if (durations.length > _maxSamples) {
      durations.removeAt(0);
    }

    if (kDebugMode) {
      debugPrint('PerformanceMonitor: $operationName took ${duration}ms');
    }
  }

  /// Time a synchronous operation
  static T timeOperation<T>(
    OperationName operationName,
    T Function() operation,
  ) {
    if (!_enabled) return operation();
    startTimer(operationName);
    try {
      return operation();
    } finally {
      endTimer(operationName);
    }
  }

  /// Time an asynchronous operation
  static Future<T> timeAsyncOperation<T>(
    OperationName operationName,
    Future<T> Function() operation,
  ) async {
    if (!_enabled) return operation();
    startTimer(operationName);
    try {
      return await operation();
    } finally {
      endTimer(operationName);
    }
  }

  /// Get performance statistics for an operation
  static PerformanceStats? getStats(OperationName operationName) {
    final durations = _durations[operationName];
    if (durations == null || durations.isEmpty) return null;

    final sortedDurations = List<int>.from(durations)..sort();
    final sum = durations.reduce((a, b) => a + b);
    final average = sum / durations.length;
    final median = sortedDurations[sortedDurations.length ~/ 2];
    final min = sortedDurations.first;
    final max = sortedDurations.last;

    return PerformanceStats(
      operationName: operationName,
      sampleCount: durations.length,
      averageDuration: average,
      medianDuration: median.toDouble(),
      minDuration: min,
      maxDuration: max,
    );
  }

  /// Get all performance statistics
  static Map<OperationName, PerformanceStats> getAllStats() {
    final stats = <OperationName, PerformanceStats>{};
    for (final operationName in _durations.keys) {
      final stat = getStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }
    return stats;
  }

  /// Print performance report
  static void printReport() {
    if (!_enabled || !kDebugMode) return;

    debugPrint('\n=== Performance Report ===');
    final allStats = getAllStats();

    if (allStats.isEmpty) {
      debugPrint('No performance data available');
      return;
    }

    for (final stats in allStats.values) {
      debugPrint(
        '${stats.operationName}: '
        'avg=${stats.averageDuration.toStringAsFixed(1)}ms, '
        'median=${stats.medianDuration.toStringAsFixed(1)}ms, '
        'min=${stats.minDuration}ms, '
        'max=${stats.maxDuration}ms '
        '(${stats.sampleCount} samples)',
      );
    }
    debugPrint('========================\n');
  }

  /// Clear all performance data
  static void clear() {
    _startTimes.clear();
    _durations.clear();
  }

  /// Clear data for a specific operation
  static void clearOperation(String operationName) {
    _startTimes.remove(operationName);
    _durations.remove(operationName);
  }
}

/// Performance statistics for an operation
class PerformanceStats {
  const PerformanceStats({
    required this.operationName,
    required this.sampleCount,
    required this.averageDuration,
    required this.medianDuration,
    required this.minDuration,
    required this.maxDuration,
  });

  final OperationName operationName;
  final int sampleCount;
  final double averageDuration;
  final double medianDuration;
  final int minDuration;
  final int maxDuration;

  @override
  String toString() =>
      'PerformanceStats($operationName: '
      'avg=${averageDuration.toStringAsFixed(1)}ms, '
      'median=${medianDuration.toStringAsFixed(1)}ms, '
      'min=${minDuration}ms, max=${maxDuration}ms, '
      'samples=$sampleCount)';
}
