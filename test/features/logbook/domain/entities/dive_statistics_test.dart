import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_statistics.dart';

void main() {
  group('DiveStatistics Domain Tests', () {
    // テスト用の基準日時
    final referenceDate = DateTime(2026, 9, 30, 12, 0);

    test('ログが空の場合、安全なデフォルト値が返却されること', () {
      // Arrange (準備)
      final emptyLogs = <DiveLog>[];

      // Act (実行)
      final stats = DiveStatistics.fromLogs(
        emptyLogs,
        referenceDate: referenceDate,
      );

      // Assert (検証)
      expect(stats.totalDives, 0);
      expect(stats.totalBottomTimeMinutes, 0);
      expect(stats.avgBottomTimeMinutes, 0.0);
      expect(stats.maxDepthMeter, 0.0);
      expect(stats.avgMaxDepthMeter, 0.0);
      expect(stats.avgSacRate, isNull);
      expect(stats.lastDiveDate, isNull);
      expect(stats.daysSinceLastDive, isNull);
      expect(stats.isBlankDiver, isFalse);
      expect(stats.boatDiveCount, 0);
      expect(stats.beachDiveCount, 0);
      expect(stats.recentLogs, isEmpty);
      expect(stats.statusBadgeLabel, '未経験');
    });

    test('複数ログがある場合、総本数・深度・潜水時間・SACレート・エントリー比率が正確に集計されること', () {
      // Arrange (準備)
      // ログ1: 10日前、ボート、水深25m、40分、SACレートあり、潮流中
      final log1 = DiveLog(
        id: 'log-1',
        entryTime: DateTime(2026, 9, 20, 10, 0),
        exitTime: DateTime(2026, 9, 20, 10, 40), // 40分
        location: '伊豆海洋公園',
        maxDepthMeter: 25.0,
        avgDepthMeter: 15.0,
        startPressureBar: 200,
        endPressureBar: 60, // 消費 140 bar
        tankVolumeLiter: 10.0,
        entryMethod: 'ボート',
        underwaterCurrent: '中',
        rating: 4,
      );

      // ログ2: 20日前、ビーチ、水深15m、50分、SACレートあり、潮流なし
      final log2 = DiveLog(
        id: 'log-2',
        entryTime: DateTime(2026, 9, 10, 9, 0),
        exitTime: DateTime(2026, 9, 10, 9, 50), // 50分
        location: '大瀬崎 湾内',
        maxDepthMeter: 15.0,
        avgDepthMeter: 10.0,
        startPressureBar: 200,
        endPressureBar: 80, // 消費 120 bar
        tankVolumeLiter: 10.0,
        entryMethod: 'ビーチ',
        underwaterCurrent: 'なし',
        rating: 5,
      );

      // ログ3: 30日前、ボート、水深30m、30分、SACレートあり、潮流強
      final log3 = DiveLog(
        id: 'log-3',
        entryTime: DateTime(2026, 8, 31, 11, 0),
        exitTime: DateTime(2026, 8, 31, 11, 30), // 30分
        location: '神子元島',
        maxDepthMeter: 30.0,
        avgDepthMeter: 18.0,
        startPressureBar: 200,
        endPressureBar: 50, // 消費 150 bar
        tankVolumeLiter: 10.0,
        entryMethod: 'ボート',
        underwaterCurrent: '強',
        rating: 5,
      );

      final logs = [log2, log3, log1]; // あえてランダム順

      // Act (実行)
      final stats = DiveStatistics.fromLogs(
        logs,
        referenceDate: referenceDate,
      );

      // Assert (検証)
      // 1. 本数・時間
      expect(stats.totalDives, 3);
      expect(stats.totalBottomTimeMinutes, 40 + 50 + 30); // 120分
      expect(stats.totalBottomTimeFormatted, '2時間 0分');
      expect(stats.avgBottomTimeMinutes, 40.0); // 120 / 3

      // 2. 水深
      expect(stats.maxDepthMeter, 30.0); // 最大は神子元島の30m
      expect(stats.avgMaxDepthMeter, (25.0 + 15.0 + 30.0) / 3); // 23.333...

      // 3. SACレート（3本すべての平均）
      expect(stats.avgSacRate, isNotNull);
      final expectedSac = (log1.calculateSacRate() +
              log2.calculateSacRate() +
              log3.calculateSacRate()) /
          3;
      expect(stats.avgSacRate, closeTo(expectedSac, 0.001));

      // 4. エントリー比率
      expect(stats.boatDiveCount, 2);
      expect(stats.beachDiveCount, 1);
      expect(stats.boatRatio, closeTo(2 / 3, 0.001));
      expect(stats.beachRatio, closeTo(1 / 3, 0.001));

      // 5. 潮流経験
      expect(stats.currentExperienceMap['強'], 1);
      expect(stats.currentExperienceMap['中'], 1);
      expect(stats.currentExperienceMap['なし'], 1);
      expect(stats.currentExperienceMap['弱'], 0);

      // 6. 最終潜水日 & 経過日数（2026/09/20 から 2026/09/30 = 10日）
      expect(stats.lastDiveDate, log1.entryTime);
      expect(stats.daysSinceLastDive, 10);
      expect(stats.isBlankDiver, isFalse);
      expect(stats.statusBadgeLabel, 'アクティブ（好調）');

      // 7. 直近ログ（最新順にソートされていること）
      expect(stats.recentLogs.length, 3);
      expect(stats.recentLogs.first.id, 'log-1');
      expect(stats.recentLogs.last.id, 'log-3');
    });

    test('最終潜水日から180日以上経過している場合、ブランクダイバーと判定されること', () {
      // Arrange (準備): 200日前のログ1件
      final oldLog = DiveLog(
        id: 'old-log',
        entryTime: referenceDate.subtract(const Duration(days: 200)),
        exitTime: referenceDate
            .subtract(const Duration(days: 200))
            .add(const Duration(minutes: 45)),
        location: '沖縄・慶良間',
        maxDepthMeter: 20.0,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 70,
        entryMethod: 'ボート',
      );

      // Act (実行)
      final stats = DiveStatistics.fromLogs(
        [oldLog],
        referenceDate: referenceDate,
      );

      // Assert (検証)
      expect(stats.daysSinceLastDive, 200);
      expect(stats.isBlankDiver, isTrue);
      expect(stats.statusBadgeLabel, 'ブランクあり（要リフレッシュ）');
    });
  });
}
