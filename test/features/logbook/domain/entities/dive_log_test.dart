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
      // Arrange
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

    test('新項目（評価、センター、潮流、潮汐、バディ、生物、計画値）が正しく保持されること', () {
      // Arrange & Act
      final log = DiveLog(
        id: 'test-rich',
        entryTime: baseEntryTime,
        exitTime: baseExitTime,
        location: '富戸・ヨコバマ',
        diveCenter: '富戸ダイビングサービス',
        rating: 5,
        divePurpose: 'ファンダイビング',
        entryMethod: 'ビーチ',
        waterArea: '海洋',
        waterType: '海水',
        maxDepthMeter: 22.0,
        avgDepthMeter: 14.0,
        startPressureBar: 200,
        endPressureBar: 60,
        tankVolumeLiter: 12.0,
        cylinderMaterial: 'スチール',
        weightKg: 5.0,
        plannedDepthMeter: 25.0,
        plannedDurationMinutes: 50,
        plannedReservePressureBar: 50.0,
        weather: '晴れ',
        airTemp: 27.0,
        waterTempMin: 22.0,
        waterTempMax: 24.0,
        visibilityMeter: 18.0,
        underwaterCurrent: '弱',
        surfaceCurrent: '穏やか',
        tideType: '大潮',
        highTideTime1: '05:30',
        lowTideTime1: '11:45',
        highTideTime2: '17:50',
        lowTideTime2: '23:55',
        buddies: ['鈴木バディ', '田中バディ'],
        marineLife: ['ネコザメ', 'タカベ群れ'],
        equipment: '5mmジャージ',
        notes: 'ネコザメの幼体を確認。',
      );

      // Assert
      expect(log.rating, equals(5));
      expect(log.diveCenter, equals('富戸ダイビングサービス'));
      expect(log.tideType, equals('大潮'));
      expect(log.highTideTime1, equals('05:30'));
      expect(log.buddies.length, equals(2));
      expect(log.marineLife, contains('ネコザメ'));
      expect(log.plannedDepthMeter, equals(25.0));
      expect(log.weightKg, equals(5.0));
    });

    test('scheduleId: 予定IDが正しく保持され、copyWithで更新できること', () {
      // Arrange
      final log = DiveLog(
        id: 'test-sched',
        scheduleId: 'sch-100',
        entryTime: baseEntryTime,
        exitTime: baseExitTime,
        location: '伊豆海洋公園',
        maxDepthMeter: 18.0,
        avgDepthMeter: 10.0,
        startPressureBar: 200,
        endPressureBar: 50,
      );

      // Assert
      expect(log.scheduleId, equals('sch-100'));

      // Act: copyWith
      final updated = log.copyWith(scheduleId: 'sch-200', location: '大瀬崎');

      // Assert
      expect(updated.scheduleId, equals('sch-200'));
      expect(updated.location, equals('大瀬崎'));
      expect(updated.id, equals('test-sched'));
    });

    test('異常系: エントリー時刻がエグジット時刻より後の場合、ArgumentErrorが発生すること', () {
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

    test('異常系: 評価が1未満または5を超える場合、ArgumentErrorが発生すること', () {
      expect(
        () => DiveLog(
          id: 'invalid-rating-low',
          entryTime: baseEntryTime,
          exitTime: baseExitTime,
          maxDepthMeter: 18.0,
          avgDepthMeter: 10.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
          rating: 0,
        ),
        throwsArgumentError,
      );

      expect(
        () => DiveLog(
          id: 'invalid-rating-high',
          entryTime: baseEntryTime,
          exitTime: baseExitTime,
          maxDepthMeter: 18.0,
          avgDepthMeter: 10.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
          rating: 6,
        ),
        throwsArgumentError,
      );
    });

    test('異常系: 最低水温が最高水温より高い場合、ArgumentErrorが発生すること', () {
      expect(
        () => DiveLog(
          id: 'invalid-temp',
          entryTime: baseEntryTime,
          exitTime: baseExitTime,
          maxDepthMeter: 18.0,
          avgDepthMeter: 10.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
          waterTempMin: 25.0,
          waterTempMax: 20.0, // 逆転
        ),
        throwsArgumentError,
      );
    });

    test('異常系: ウェイト量が負数の場合、ArgumentErrorが発生すること', () {
      expect(
        () => DiveLog(
          id: 'invalid-weight',
          entryTime: baseEntryTime,
          exitTime: baseExitTime,
          maxDepthMeter: 18.0,
          avgDepthMeter: 10.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '大瀬崎',
          weightKg: -1.0,
        ),
        throwsArgumentError,
      );
    });

    test('選択された機材ID一覧（selectedGearIds）が正しく保持され、copyWithで更新できること', () {
      // Arrange & Act
      final log = DiveLog(
        id: 'gear-test-log',
        entryTime: baseEntryTime,
        exitTime: baseExitTime,
        maxDepthMeter: 18.0,
        avgDepthMeter: 10.0,
        startPressureBar: 200,
        endPressureBar: 50,
        location: '大瀬崎',
        selectedGearIds: ['gear-1', 'gear-2'],
      );

      // Assert
      expect(log.selectedGearIds, equals(['gear-1', 'gear-2']));

      // Act (copyWith)
      final updated = log.copyWith(selectedGearIds: ['gear-1', 'gear-2', 'gear-3']);

      // Assert
      expect(updated.selectedGearIds, equals(['gear-1', 'gear-2', 'gear-3']));
    });
  });
}
