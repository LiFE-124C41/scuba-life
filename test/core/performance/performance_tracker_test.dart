import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/performance/infrastructure/firebase_performance_tracker.dart';
import 'package:scuba_life/core/performance/infrastructure/in_memory_performance_tracker.dart';

void main() {
  group('PerformanceTracker Unit Tests', () {
    test('InMemoryPerformanceTracker: トレースとメトリックが正常に記録されること', () async {
      final tracker = InMemoryPerformanceTracker();
      await tracker.initialize();
      expect(tracker.isInitialized, isTrue);

      final result = await tracker.trace(
        'fetch_dive_spots',
        () async {
          return ['Spot 1', 'Spot 2', 'Spot 3'];
        },
        attributes: {'category': 'popular'},
        metrics: {'spot_count': 3},
      );

      expect(result.length, 3);
      expect(tracker.recordedTraces.length, 1);

      final recorded = tracker.recordedTraces.first;
      expect(recorded.name, 'fetch_dive_spots');
      expect(recorded.attributes['category'], 'popular');
      expect(recorded.metrics['spot_count'], 3);
      expect(recorded.isCompleted, isTrue);
    });

    test('InMemoryPerformanceTracker: 手動ハンドルでの属性追加とメトリック加算', () async {
      final tracker = InMemoryPerformanceTracker();
      final handle = tracker.startTrace('custom_batch_upload');

      handle.putAttribute('type', 'dive_log_photo');
      handle.setMetric('photo_count', 2);
      handle.incrementMetric('photo_count', 1); // 3
      await handle.stop();

      expect(tracker.recordedTraces.length, 1);
      final recorded = tracker.recordedTraces.first;
      expect(recorded.name, 'custom_batch_upload');
      expect(recorded.attributes['type'], 'dive_log_photo');
      expect(recorded.metrics['photo_count'], 3);
      expect(recorded.isCompleted, isTrue);
    });

    test('FirebasePerformanceTracker: Firebase未初期化時はエラーにならずフォールバック動作すること', () async {
      final tracker = FirebasePerformanceTracker();
      await tracker.initialize();

      final result = await tracker.trace(
        'fallback_trace',
        () async => 42,
        attributes: {'test': 'true'},
      );

      expect(result, 42);

      final handle = tracker.startTrace('fallback_manual');
      handle.putAttribute('k', 'v');
      handle.setMetric('m', 10);
      handle.incrementMetric('m', 5);
      await handle.stop();
      // 例外が発生しないことを確認
    });
  });
}
