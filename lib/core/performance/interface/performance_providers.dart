import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/performance_tracker.dart';
import '../infrastructure/firebase_performance_tracker.dart';

/// パフォーマンスモニタリングのプロバイダー
final performanceTrackerProvider = Provider<PerformanceTracker>((ref) {
  final tracker = FirebasePerformanceTracker();
  return tracker;
});
