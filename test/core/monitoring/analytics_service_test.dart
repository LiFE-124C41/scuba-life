import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/monitoring/infrastructure/in_memory_analytics_service.dart';

void main() {
  group('InMemoryAnalyticsService Tests', () {
    late InMemoryAnalyticsService analyticsService;

    setUp(() {
      analyticsService = InMemoryAnalyticsService();
    });

    test('ユーザーIDおよびユーザープロパティが正しく保持されること', () async {
      // Arrange
      expect(analyticsService.currentUserId, isNull);

      // Act
      await analyticsService.setUserId('user-123');
      await analyticsService.setUserProperty(
        name: 'certification_org',
        value: 'PADI',
      );

      // Assert
      expect(analyticsService.currentUserId, 'user-123');
      expect(analyticsService.userProperties['certification_org'], 'PADI');
    });

    test('ダイブログ作成イベントが正確なパラメータで記録されること', () async {
      // Arrange & Act
      await analyticsService.logDiveLogCreated(
        spotName: '大瀬崎 湾内',
        maxDepth: 22.4,
        durationMinutes: 45,
        rating: 5,
      );

      // Assert
      expect(analyticsService.recordedEvents.length, 1);
      final event = analyticsService.recordedEvents.first;
      expect(event.name, 'dive_log_created');
      expect(event.parameters?['spot_name'], '大瀬崎 湾内');
      expect(event.parameters?['max_depth'], 22.4);
      expect(event.parameters?['duration_minutes'], 45);
      expect(event.parameters?['rating'], 5);
    });

    test('SACレート計算イベントが正確なパラメータで記録されること', () async {
      // Arrange & Act
      await analyticsService.logSacCalculated(
        sacRate: 14.8,
        avgDepth: 12.0,
        durationMinutes: 45,
      );

      // Assert
      expect(analyticsService.recordedEvents.length, 1);
      final event = analyticsService.recordedEvents.first;
      expect(event.name, 'sac_calculated');
      expect(event.parameters?['sac_rate'], 14.8);
      expect(event.parameters?['avg_depth'], 12.0);
      expect(event.parameters?['duration_minutes'], 45);
    });

    test('マイ機材登録およびオーバーホール完了イベントが正確に記録されること', () async {
      // Act
      await analyticsService.logGearCreated(
        name: 'レギュレーター AXiS',
        category: 'regulator',
      );
      await analyticsService.logOverhaulCompleted(
        gearName: 'レギュレーター AXiS',
        category: 'regulator',
        divesReset: 80,
      );

      // Assert
      expect(analyticsService.recordedEvents.length, 2);
      expect(analyticsService.recordedEvents[0].name, 'gear_created');
      expect(analyticsService.recordedEvents[0].parameters?['gear_name'], 'レギュレーター AXiS');
      expect(analyticsService.recordedEvents[1].name, 'overhaul_completed');
      expect(analyticsService.recordedEvents[1].parameters?['dives_reset'], 80);
    });

    test('画面表示イベントおよびclearによる初期化が正常に動作すること', () async {
      // Act
      await analyticsService.logScreenView(screenName: 'DiveLogPage');
      expect(analyticsService.recordedEvents.length, 1);

      analyticsService.clear();

      // Assert
      expect(analyticsService.recordedEvents, isEmpty);
      expect(analyticsService.userProperties, isEmpty);
      expect(analyticsService.currentUserId, isNull);
    });
  });
}
