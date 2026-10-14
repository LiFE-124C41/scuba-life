import '../domain/performance_tracker.dart';

/// テスト用・記録済みトレースデータ
class RecordedTrace {
  final String name;
  final Map<String, String> attributes;
  final Map<String, int> metrics;
  final bool isCompleted;

  RecordedTrace({
    required this.name,
    required this.attributes,
    required this.metrics,
    this.isCompleted = false,
  });

  RecordedTrace copyWith({
    String? name,
    Map<String, String>? attributes,
    Map<String, int>? metrics,
    bool? isCompleted,
  }) {
    return RecordedTrace(
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      metrics: metrics ?? this.metrics,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// InMemory トレースハンドル
class InMemoryTraceHandle implements TraceHandle {
  final String name;
  final InMemoryPerformanceTracker tracker;
  final Map<String, String> attributes = {};
  final Map<String, int> metrics = {};

  InMemoryTraceHandle({
    required this.name,
    required this.tracker,
  });

  @override
  void putAttribute(String name, String value) {
    attributes[name] = value;
  }

  @override
  void setMetric(String name, int value) {
    metrics[name] = value;
  }

  @override
  void incrementMetric(String name, int by) {
    metrics[name] = (metrics[name] ?? 0) + by;
  }

  @override
  Future<void> stop() async {
    tracker.recordTrace(
      RecordedTrace(
        name: name,
        attributes: Map.from(attributes),
        metrics: Map.from(metrics),
        isCompleted: true,
      ),
    );
  }
}

/// 単体テスト用 InMemory Performance Tracker
class InMemoryPerformanceTracker implements PerformanceTracker {
  bool isInitialized = false;
  bool isEnabled = true;
  final List<RecordedTrace> recordedTraces = [];

  void recordTrace(RecordedTrace trace) {
    recordedTraces.add(trace);
  }

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    isEnabled = enabled;
  }

  @override
  TraceHandle startTrace(String name) {
    return InMemoryTraceHandle(name: name, tracker: this);
  }

  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    final handle = InMemoryTraceHandle(name: name, tracker: this);
    if (attributes != null) {
      attributes.forEach((k, v) => handle.putAttribute(k, v));
    }
    if (metrics != null) {
      metrics.forEach((k, v) => handle.setMetric(k, v));
    }

    try {
      return await action();
    } finally {
      await handle.stop();
    }
  }

  void clear() {
    recordedTraces.clear();
  }
}
