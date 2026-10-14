import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../domain/performance_tracker.dart';

/// Firebase Performance Monitoring 本番用トレースハンドル
class FirebaseTraceHandle implements TraceHandle {
  final Trace _trace;

  FirebaseTraceHandle(this._trace);

  @override
  void putAttribute(String name, String value) {
    try {
      _trace.putAttribute(name, value);
    } catch (e) {
      debugPrint('PerformanceTrace putAttribute error ($name): $e');
    }
  }

  @override
  void setMetric(String name, int value) {
    try {
      _trace.setMetric(name, value);
    } catch (e) {
      debugPrint('PerformanceTrace setMetric error ($name): $e');
    }
  }

  @override
  void incrementMetric(String name, int by) {
    try {
      _trace.incrementMetric(name, by);
    } catch (e) {
      debugPrint('PerformanceTrace incrementMetric error ($name): $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _trace.stop();
    } catch (e) {
      debugPrint('PerformanceTrace stop error: $e');
    }
  }
}

/// テスト環境・非初期化時のNo-Opハンドル
class NoOpTraceHandle implements TraceHandle {
  @override
  void putAttribute(String name, String value) {}

  @override
  void setMetric(String name, int value) {}

  @override
  void incrementMetric(String name, int by) {}

  @override
  Future<void> stop() async {}
}

/// Firebase Performance Monitoring 実装
class FirebasePerformanceTracker implements PerformanceTracker {
  final FirebasePerformance? _injectedPerformance;
  FirebasePerformance? _performance;
  bool _isAvailable = false;

  FirebasePerformanceTracker({FirebasePerformance? performance})
      : _injectedPerformance = performance;

  @override
  Future<void> initialize() async {
    try {
      if (_injectedPerformance != null) {
        _performance = _injectedPerformance;
        _isAvailable = true;
        return;
      }

      if (Firebase.apps.isNotEmpty) {
        _performance = FirebasePerformance.instance;
        _isAvailable = true;
      } else {
        _isAvailable = false;
      }
    } catch (e) {
      debugPrint('FirebasePerformance initialization fallback: $e');
      _isAvailable = false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    if (!_isAvailable || _performance == null) return;
    try {
      await _performance!.setPerformanceCollectionEnabled(enabled);
    } catch (e) {
      debugPrint('setPerformanceCollectionEnabled error: $e');
    }
  }

  @override
  TraceHandle startTrace(String name) {
    if (!_isAvailable || _performance == null) {
      return NoOpTraceHandle();
    }
    try {
      final trace = _performance!.newTrace(name);
      trace.start().ignore();
      return FirebaseTraceHandle(trace);
    } catch (e) {
      debugPrint('startTrace error ($name): $e');
      return NoOpTraceHandle();
    }
  }

  @override
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    if (!_isAvailable || _performance == null) {
      return await action();
    }

    Trace? trace;
    try {
      trace = _performance!.newTrace(name);
      await trace.start();
      if (attributes != null) {
        attributes.forEach((k, v) => trace?.putAttribute(k, v));
      }
      if (metrics != null) {
        metrics.forEach((k, v) => trace?.setMetric(k, v));
      }
    } catch (e) {
      debugPrint('Failed to start trace ($name): $e');
    }

    try {
      return await action();
    } finally {
      try {
        await trace?.stop();
      } catch (e) {
        debugPrint('Failed to stop trace ($name): $e');
      }
    }
  }
}
