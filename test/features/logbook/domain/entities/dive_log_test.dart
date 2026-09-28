import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';

void main() {
  group('DiveLog Entity & Domain Logic Tests', () {
    // Arrange: テストデータのセットアップ
    final baseEntryTime = DateTime(2026, 9, 28, 10, 0);
    final baseExitTime = DateTime(2026, 9, 28, 10, 45); // 45分ダイブ

    test('ダイビング時間と消費気圧が正しく計算されること', () {
      // Arrange
      final log = DiveLog(
        id: 'test-1',
        entryTime: baseEntryTime,
        exitTime: baseExitTime,
        maxDepthMeter: 20.0,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        location: '大瀬崎',
      );

      // Act
      final bottomTime = log.bottomTimeMinutes;
      final consumedPressure = log.consumedPressureBar;

      // Assert
      expect(bottomTime, equals(45));
      expect(consumedPressure, equals(150.0));
    });

    test('SACレート (水面空気消費率) が物理計算式に従って正確に算出されること', () {
      // Arrange:
      // 潜水時間: 45分
      // 平均水深: 10m -> 環境圧 = 1 + 10/10 = 2.0 atm
      // 開始圧: 200 bar, 終了圧: 50 bar -> 消費圧: 150 bar
      // タンク容量: 10 L -> 消費量: 150 * 10 = 1500 L
      // SACレート = 1500 / (45 * 2.0) = 1500 / 90 = 16.666... L/min
      final log = DiveLog(
        id: 'test-sac',
        entryTime: baseEntryTime,
        exitTime: baseExitTime,
        maxDepthMeter: 18.0,
        avgDepthMeter: 10.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        location: '大瀬崎',
      );

      // Act
      final sacRate = log.calculateSacRate();

      // Assert
      expect(sacRate, closeTo(16.66, 0.01));
    });

    test('異常系: エントリー時刻がエグジット時刻より後の場合、ArgumentErrorが発生すること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveLog(
          id: 'invalid-time',
          entryTime: baseExitTime,
          exitTime: baseEntryTime, // 逆転
          maxDepthMeter: 18.0,
          avgDepthMeter: 10.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
        ),
        throwsArgumentError,
      );
    });

    test('異常系: 平均水深が最大水深を超える場合、ArgumentErrorが発生すること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveLog(
          id: 'invalid-depth',
          entryTime: baseEntryTime,
          exitTime: baseExitTime,
          maxDepthMeter: 10.0,
          avgDepthMeter: 15.0, // 平均が最大を超えている
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
        ),
        throwsArgumentError,
      );
    });
  });
}
