import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

/// Service for monitoring app performance and detecting memory issues
@singleton
class PerformanceMonitorService {
  PerformanceMonitorService(this._logger);

  final Logger _logger;
  Timer? _monitoringTimer;
  final Map<String, int> _operationCounts = {};
  final Map<String, Duration> _operationDurations = {};
  DateTime? _lastReportTime;

  /// Start performance monitoring
  void startMonitoring() {
    _lastReportTime = DateTime.now();
    
    _monitoringTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _reportMetrics();
    });

    _logger.i('Performance monitoring started');
  }

  /// Track an operation execution time
  Future<T> trackOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();
      stopwatch.stop();

      _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
      
      final existingDuration = _operationDurations[operationName] ?? Duration.zero;
      _operationDurations[operationName] = existingDuration + stopwatch.elapsed;

      // Warn if operation is slow
      if (stopwatch.elapsedMilliseconds > 1000) {
        _logger.w('Slow operation: $operationName took ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.e('Operation $operationName failed after ${stopwatch.elapsedMilliseconds}ms', error: e);
      rethrow;
    }
  }

  /// Report performance metrics
  void _reportMetrics() {
    if (_operationCounts.isEmpty) return;

    final now = DateTime.now();
    final timeSinceLastReport = now.difference(_lastReportTime ?? now);

    _logger.i('=== Performance Report (${timeSinceLastReport.inMinutes}m) ===');

    _operationCounts.forEach((operation, count) {
      final totalDuration = _operationDurations[operation] ?? Duration.zero;
      final avgDuration = totalDuration.inMilliseconds / count;

      _logger.i('$operation: $count ops, avg ${avgDuration.toStringAsFixed(1)}ms');
    });

    _logger.i('===========================================');

    _lastReportTime = now;
  }

  /// Record a custom metric
  void recordMetric(String metricName, double value) {
    _logger.d('Metric: $metricName = ${value.toStringAsFixed(2)}');
  }

  /// Stop monitoring and cleanup
  void dispose() {
    _monitoringTimer?.cancel();
    _reportMetrics(); // Final report
    _operationCounts.clear();
    _operationDurations.clear();
    _logger.i('Performance monitoring stopped');
  }
}
