import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/marine_life/domain/entities/marine_life_summary.dart';

void main() {
  group('MarineLifeSummary (ドメインモデル集計ロジックUT)', () {
    // 共通テスト用ヘルパー関数
    DiveLog createLog({
      required String id,
      required DateTime entryTime,
      required String location,
      required double maxDepth,
      required List<String> marineLife,
    }) {
      return DiveLog(
        id: id,
        entryTime: entryTime,
        exitTime: entryTime.add(const Duration(minutes: 45)),
        location: location,
        maxDepthMeter: maxDepth,
        avgDepthMeter: maxDepth * 0.6,
        startPressureBar: 200,
        endPressureBar: 50,
        marineLife: marineLife,
      );
    }

    test('ログが空の場合は空のリストを返却すること (Arrange-Act-Assert)', () {
      // Arrange
      final logs = <DiveLog>[];

      // Act
      final result = MarineLifeSummary.fromLogsList(logs);

      // Assert
      expect(result, isEmpty);
    });

    test('生物名ごとに遭遇回数・出現月・出会った場所・最大水深が正しく集約されること', () {
      // Arrange
      final logs = [
        createLog(
          id: 'log-1',
          entryTime: DateTime(2026, 7, 15, 10, 0),
          location: '伊豆大瀬崎 湾内',
          maxDepth: 18.5,
          marineLife: ['アオウミガメ', 'クマノミ'],
        ),
        createLog(
          id: 'log-2',
          entryTime: DateTime(2026, 8, 20, 11, 0),
          location: '伊豆大瀬崎 先端',
          maxDepth: 25.0,
          marineLife: ['クマノミ', 'キンギョハナダイ'],
        ),
        createLog(
          id: 'log-3',
          entryTime: DateTime(2026, 11, 5, 9, 30),
          location: '沖縄本島 万座毛',
          maxDepth: 30.0,
          marineLife: ['アオウミガメ', 'マンタ'],
        ),
      ];

      // Act
      final summaries = MarineLifeSummary.fromLogsList(logs);

      // Assert
      // アオウミガメ: 2回遭遇（7月, 11月 / 大瀬崎 湾内, 万座毛 / 最大深度30.0m）
      // クマノミ: 2回遭遇（7月, 8月 / 大瀬崎 湾内, 大瀬崎 先端 / 最大深度25.0m）
      // キンギョハナダイ: 1回遭遇
      // マンタ: 1回遭遇
      expect(summaries.length, 4);

      final turtle = summaries.firstWhere((s) => s.name == 'アオウミガメ');
      expect(turtle.encounterCount, 2);
      expect(turtle.months, [7, 11]);
      expect(turtle.locations, containsAll(['伊豆大瀬崎 湾内', '沖縄本島 万座毛']));
      expect(turtle.maxDepthMeter, 30.0);
      expect(turtle.firstEncounterDate, DateTime(2026, 7, 15, 10, 0));
      expect(turtle.lastEncounterDate, DateTime(2026, 11, 5, 9, 30));

      final clownfish = summaries.firstWhere((s) => s.name == 'クマノミ');
      expect(clownfish.encounterCount, 2);
      expect(clownfish.months, [7, 8]);
      expect(clownfish.locations, containsAll(['伊豆大瀬崎 湾内', '伊豆大瀬崎 先端']));
      expect(clownfish.maxDepthMeter, 25.0);
    });

    test('1つのログ内で同一生物が複数記載されていた場合に重複カウントしないこと', () {
      // Arrange: 同一ログに「アオウミガメ」が2回記載
      final logs = [
        createLog(
          id: 'log-1',
          entryTime: DateTime(2026, 5, 1, 10, 0),
          location: '慶良間諸島',
          maxDepth: 15.0,
          marineLife: ['アオウミガメ', '  アオウミガメ  ', 'チンアナゴ'],
        ),
      ];

      // Act
      final summaries = MarineLifeSummary.fromLogsList(logs);

      // Assert
      final turtle = summaries.firstWhere((s) => s.name == 'アオウミガメ');
      expect(turtle.encounterCount, 1);
      expect(turtle.locations, ['慶良間諸島']);
    });

    test('空白のみの名前や空文字が適切に除外されること', () {
      // Arrange
      final logs = [
        createLog(
          id: 'log-1',
          entryTime: DateTime(2026, 6, 10, 10, 0),
          location: '伊豆海洋公園',
          maxDepth: 20.0,
          marineLife: ['', '   ', 'タカベ'],
        ),
      ];

      // Act
      final summaries = MarineLifeSummary.fromLogsList(logs);

      // Assert
      expect(summaries.length, 1);
      expect(summaries.first.name, 'タカベ');
    });

    test('遭遇回数が多い順にソートされ、同数の場合は五十音順に並ぶこと', () {
      // Arrange
      final logs = [
        createLog(
          id: 'log-1',
          entryTime: DateTime(2026, 8, 1, 10, 0),
          location: '串本',
          maxDepth: 18.0,
          marineLife: ['ウミウシ', 'サメ'],
        ),
        createLog(
          id: 'log-2',
          entryTime: DateTime(2026, 8, 2, 10, 0),
          location: '串本',
          maxDepth: 18.0,
          marineLife: ['サメ', 'エイ'],
        ),
      ];

      // Act
      final summaries = MarineLifeSummary.fromLogsList(logs);

      // Assert:
      // サメ: 2回 (1位)
      // ウミウシ, エイ: 各1回 (五十音順で 'エイ' -> 'ウミウシ')
      expect(summaries[0].name, 'サメ');
      expect(summaries[0].encounterCount, 2);
      expect(summaries[1].name, 'ウミウシ');
      expect(summaries[2].name, 'エイ');
    });
  });
}
