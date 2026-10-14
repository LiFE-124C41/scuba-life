import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/monitoring/infrastructure/in_memory_analytics_service.dart';
import 'package:scuba_life/core/monitoring/infrastructure/in_memory_crash_reporting_service.dart';
import 'package:scuba_life/core/monitoring/interface/monitoring_providers.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/interface/controllers/user_profile_controller.dart';

void main() {
  group('monitoringSyncProvider Tests', () {
    late InMemoryAnalyticsService fakeAnalytics;
    late InMemoryCrashReportingService fakeCrashReporting;

    setUp(() {
      fakeAnalytics = InMemoryAnalyticsService();
      fakeCrashReporting = InMemoryCrashReportingService();
    });

    test('ログイン中ユーザーのプロファイルが変更された際、ユーザーIDとCカード情報が自動同期されること', () async {
      // Arrange
      const user = UserAccount(
        id: 'diver-42',
        email: 'diver@example.com',
        displayName: 'Ocean Lover',
        certificationOrg: 'NAUI',
        certificationLevel: 'Master Diver',
      );

      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(fakeAnalytics),
          crashReportingServiceProvider.overrideWithValue(fakeCrashReporting),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        ],
      );
      addTearDown(container.dispose);

      // Act: monitoringSyncProvider を listen してストリームの解決を待つ
      container.listen(monitoringSyncProvider, (_, _) {});
      await container.read(currentUserProfileProvider.future);

      // Assert
      expect(fakeAnalytics.currentUserId, 'diver-42');
      expect(fakeAnalytics.userProperties['certification_org'], 'NAUI');
      expect(fakeAnalytics.userProperties['certification_level'], 'Master Diver');

      expect(fakeCrashReporting.currentUserId, 'diver-42');
      expect(fakeCrashReporting.customKeys['c_card_org'], 'NAUI');
      expect(fakeCrashReporting.customKeys['c_card_level'], 'Master Diver');
    });

    test('未ログイン状態の場合、ユーザーIDがクリアされること', () async {
      // Arrange
      fakeAnalytics.currentUserId = 'old-user';

      final container = ProviderContainer(
        overrides: [
          analyticsServiceProvider.overrideWithValue(fakeAnalytics),
          crashReportingServiceProvider.overrideWithValue(fakeCrashReporting),
          currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);

      // Act
      container.listen(monitoringSyncProvider, (_, _) {});
      await container.read(currentUserProfileProvider.future);

      // Assert
      expect(fakeAnalytics.currentUserId, isNull);
    });
  });
}
