import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/monitoring/infrastructure/in_memory_crash_reporting_service.dart';

void main() {
  group('InMemoryCrashReportingService Tests', () {
    late InMemoryCrashReportingService crashService;

    setUp(() {
      crashService = InMemoryCrashReportingService();
    });

    test('エラーの記録とスタックトレース・理由が保持されること', () async {
      // Arrange
      final exception = Exception('ネットワーク切断');
      final stack = StackTrace.current;

      // Act
      await crashService.recordError(
        exception,
        stack,
        reason: '洋上ボートでのログ同期失敗',
        information: ['spotId: osezaki', 'retry: 3'],
        fatal: false,
      );

      // Assert
      expect(crashService.recordedErrors.length, 1);
      final recorded = crashService.recordedErrors.first;
      expect(recorded.exception, exception);
      expect(recorded.stackTrace, stack);
      expect(recorded.reason, '洋上ボートでのログ同期失敗');
      expect(recorded.information, ['spotId: osezaki', 'retry: 3']);
      expect(recorded.fatal, isFalse);
    });

    test('ユーザーIDおよびオフラインステータス・Cカード情報がカスタムキーに正しく設定されること', () async {
      // Act
      await crashService.setUserId('user-999');
      await crashService.setOfflineMode(true);
      await crashService.setCertificationInfo(org: 'PADI', level: 'AOW');

      // Assert
      expect(crashService.currentUserId, 'user-999');
      expect(crashService.customKeys['is_offline'], true);
      expect(crashService.customKeys['c_card_org'], 'PADI');
      expect(crashService.customKeys['c_card_level'], 'AOW');
    });

    test('ログメッセージが時系列で蓄積され、clearで初期化されること', () async {
      // Act
      await crashService.log('ログイン成功');
      await crashService.log('ログ一覧読み込み開始');

      expect(crashService.logs.length, 2);
      expect(crashService.logs[0], 'ログイン成功');

      crashService.clear();

      // Assert
      expect(crashService.logs, isEmpty);
      expect(crashService.recordedErrors, isEmpty);
      expect(crashService.customKeys, isEmpty);
      expect(crashService.currentUserId, isNull);
    });
  });
}
