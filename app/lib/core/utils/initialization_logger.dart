import 'package:logger/logger.dart';

/// Timeline event for tracking Matrix client initialization
class InitializationTimelineEvent {
  InitializationTimelineEvent({
    required this.timestamp,
    required this.component,
    required this.event,
    required this.details,
  });

  final DateTime timestamp;
  final String component;
  final String event;
  final Map<String, dynamic> details;

  Duration timeFrom(InitializationTimelineEvent other) {
    return timestamp.difference(other.timestamp);
  }

  @override
  String toString() {
    final formattedTime = timestamp.toString().split('.')[0];
    return '[$formattedTime] [$component] $event - ${_formatDetails()}';
  }

  String _formatDetails() {
    final entries = details.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return entries.isNotEmpty ? '{$entries}' : '';
  }
}

/// Initialization logger - tracks Matrix client initialization timeline
class InitializationLogger {
  static final InitializationLogger _instance = InitializationLogger._internal();

  factory InitializationLogger() {
    return _instance;
  }

  InitializationLogger._internal();

  final Logger _logger = Logger();
  final List<InitializationTimelineEvent> _timeline = [];
  DateTime? _authStartTime;
  DateTime? _initStartTime;
  DateTime? _initCompleteTime;

  /// Log an event in the initialization timeline
  void logEvent({
    required String component,
    required String event,
    Map<String, dynamic> details = const {},
  }) {
    final timelineEvent = InitializationTimelineEvent(
      timestamp: DateTime.now(),
      component: component,
      event: event,
      details: details,
    );

    _timeline.add(timelineEvent);
    _logger.d(timelineEvent.toString());

    // Track key milestones
    if (component == 'AuthBloc' && event == 'emit_authenticated') {
      _authStartTime = timelineEvent.timestamp;
    } else if (component == 'MatrixClientService' && event == 'init_start') {
      _initStartTime = timelineEvent.timestamp;
    } else if (component == 'MatrixClientService' && event == 'init_complete') {
      _initCompleteTime = timelineEvent.timestamp;
    }
  }

  /// Log when a component waits for initialization
  void logWaitStart({
    required String component,
    required String reason,
  }) {
    logEvent(
      component: component,
      event: 'waiting_for_init',
      details: {'reason': reason, 'duration': 'waiting'},
    );
  }

  /// Log when a component finishes waiting
  void logWaitEnd({
    required String component,
    required bool success,
    Duration? totalWaitTime,
  }) {
    logEvent(
      component: component,
      event: 'wait_complete',
      details: {
        'success': success,
        'wait_duration_ms': totalWaitTime?.inMilliseconds ?? 0,
      },
    );
  }

  /// Log initialization failure
  void logInitializationFailure({
    required String reason,
    required dynamic error,
  }) {
    _logger.e('Initialization failed: $reason', error: error);
    logEvent(
      component: 'MatrixClientService',
      event: 'init_failed',
      details: {'reason': reason, 'error': error.toString()},
    );
  }

  /// Get full initialization timeline for debugging
  List<InitializationTimelineEvent> getTimeline() => List.from(_timeline);

  /// Get initialization summary
  String getInitializationSummary() {
    final buffer = StringBuffer();
    buffer.writeln('=== Matrix Client Initialization Timeline ===');

    if (_authStartTime != null) {
      buffer.writeln('Auth Authenticated: $_authStartTime');
    }

    if (_initStartTime != null) {
      buffer.writeln('Init Started: $_initStartTime');
    }

    if (_initCompleteTime != null && _initStartTime != null) {
      final duration = _initCompleteTime!.difference(_initStartTime!);
      buffer.writeln('Init Completed: $_initCompleteTime');
      buffer.writeln('Init Duration: ${duration.inMilliseconds}ms');
    }

    if (_authStartTime != null && _initCompleteTime != null) {
      final totalDuration = _initCompleteTime!.difference(_authStartTime!);
      buffer.writeln('Total Auth to Init Complete: ${totalDuration.inMilliseconds}ms');
    }

    buffer.writeln('\n=== Full Timeline ===');
    for (final event in _timeline) {
      buffer.writeln(event.toString());
    }

    return buffer.toString();
  }

  /// Clear timeline (useful for test isolation)
  void clear() {
    _timeline.clear();
    _authStartTime = null;
    _initStartTime = null;
    _initCompleteTime = null;
  }

  /// Print summary to console
  void printSummary() {
    _logger.i(getInitializationSummary());
  }
}

/// Global instance for convenience
final initLogger = InitializationLogger();

/// Helper to measure initialization timing in blocks
class InitializationTimerBlock {
  InitializationTimerBlock({
    required this.component,
    required this.operation,
  }) {
    _startTime = DateTime.now();
    initLogger.logEvent(
      component: component,
      event: '${operation}_start',
      details: {},
    );
  }

  final String component;
  final String operation;
  late DateTime _startTime;

  void end({Map<String, dynamic> details = const {}}) {
    final duration = DateTime.now().difference(_startTime);
    initLogger.logEvent(
      component: component,
      event: '${operation}_end',
      details: {
        ...details,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }
}
