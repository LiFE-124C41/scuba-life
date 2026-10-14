import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/monitoring/infrastructure/in_memory_analytics_service.dart';
import 'package:scuba_life/core/monitoring/interface/monitoring_providers.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/infrastructure/repositories/in_memory_dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/infrastructure/repositories/in_memory_gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';

void main() {
  group('Controllers Monitoring Event Integration Tests', () {
    late InMemoryAnalyticsService fakeAnalytics;
    late InMemoryDiveLogRepository fakeLogRepo;
    late InMemoryGearRepository fakeGearRepo;

    setUp(() {
      fakeAnalytics = InMemoryAnalyticsService();
      fakeLogRepo = InMemoryDiveLogRepository();
      fakeGearRepo = InMemoryGearRepository();
    });

    test('DiveLogListNotifier.addLog 実行時にログ作成とSAC計算イベントが記録されること', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(fakeAnalytics),
          diveLogRepositoryProvider.overrideWithValue(fakeLogRepo),
        ],
      );
      addTearDown(container.dispose);

      final log = DiveLog(
        id: 'log-101',
        date: DateTime(2026, 10, 15),
        entryTime: DateTime(2026, 10, 15, 10, 0),
        exitTime: DateTime(2026, 10, 15, 10, 42),
        location: '串本 グラスワールド',
        maxDepthMeter: 18.5,
        avgDepthMeter: 11.2,
        startPressureBar: 200.0,
        endPressureBar: 70.0,
        tankVolumeLiter: 10.0,
        rating: 5,
      );

      // Act
      await container.read(diveLogListProvider.notifier).addLog(log);

      // Assert
      expect(fakeAnalytics.recordedEvents.length, 2);
      expect(fakeAnalytics.recordedEvents[0].name, 'dive_log_created');
      expect(fakeAnalytics.recordedEvents[0].parameters?['spot_name'], '串本 グラスワールド');
      expect(fakeAnalytics.recordedEvents[0].parameters?['max_depth'], 18.5);
      expect(fakeAnalytics.recordedEvents[0].parameters?['duration_minutes'], 42);

      expect(fakeAnalytics.recordedEvents[1].name, 'sac_calculated');
      expect(fakeAnalytics.recordedEvents[1].parameters?['duration_minutes'], 42);
    });

    test('GearListNotifier.saveGear および recordOverhaul 実行時にイベントが記録されること', () async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(fakeAnalytics),
          gearRepositoryProvider.overrideWithValue(fakeGearRepo),
        ],
      );
      addTearDown(container.dispose);

      final gear = GearItem(
        id: 'gear-101',
        name: 'TUSA レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2024, 1, 1),
        lastOverhaulDate: DateTime(2025, 1, 1),
        divesSinceOverhaul: 50,
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
      );

      // Act 1: 機材保存
      await container.read(gearListNotifierProvider.notifier).saveGear(gear);

      // Assert 1
      expect(
        fakeAnalytics.recordedEvents.any((e) =>
            e.name == 'gear_created' &&
            e.parameters?['gear_name'] == 'TUSA レギュレーター'),
        isTrue,
      );

      // Act 2: オーバーホール完了記録
      await container.read(gearListNotifierProvider.notifier).recordOverhaul(
            gearId: 'gear-101',
            overhaulDate: DateTime(2026, 10, 10),
            memo: 'ショップにて定期点検実施',
          );

      // Assert 2
      expect(
        fakeAnalytics.recordedEvents.any((e) =>
            e.name == 'overhaul_completed' &&
            e.parameters?['gear_name'] == 'TUSA レギュレーター'),
        isTrue,
      );
    });
  });
}
