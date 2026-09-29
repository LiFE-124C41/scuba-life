import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/marine_life/usecase/get_marine_life_summaries.dart';

/// テスト用モック（Mock）リポジトリ
///
/// 外部データソース（Hive等）への依存を切り離し、
/// ユースケース層の集計・絞り込み・ソートロジックを独立して検証するためのインメモリ偽装クラス。
class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs = [];

  @override
  Future<List<DiveLog>> getAllLogs() async => List.from(logs);

  @override
  Future<DiveLog?> getLogById(String id) async =>
      logs.where((l) => l.id == id).firstOrNull;

  @override
  Future<void> saveLog(DiveLog log) async {
    logs.removeWhere((l) => l.id == log.id);
    logs.add(log);
  }

  @override
  Future<void> deleteLog(String id) async {
    logs.removeWhere((l) => l.id == id);
  }
}

void main() {
  late MockDiveLogRepository mockRepository;
  late GetMarineLifeSummaries getMarineLifeSummariesUseCase;

  DiveLog createLog({
    required String id,
    required DateTime entryTime,
    required String location,
    required List<String> marineLife,
  }) {
    return DiveLog(
      id: id,
      entryTime: entryTime,
      exitTime: entryTime.add(const Duration(minutes: 45)),
      location: location,
      maxDepthMeter: 20.0,
      avgDepthMeter: 12.0,
      startPressureBar: 200,
      endPressureBar: 50,
      marineLife: marineLife,
    );
  }

  setUp(() {
    mockRepository = MockDiveLogRepository();
    getMarineLifeSummariesUseCase = GetMarineLifeSummaries(mockRepository);

    // テスト共通データのセットアップ
    mockRepository.logs.addAll([
      createLog(
        id: 'log-1',
        entryTime: DateTime(2026, 7, 10),
        location: '伊豆大瀬崎 湾内',
        marineLife: ['アオウミガメ', 'クマノミ'],
      ),
      createLog(
        id: 'log-2',
        entryTime: DateTime(2026, 8, 15),
        location: '伊豆大瀬崎 先端',
        marineLife: ['クマノミ', 'マンタ'],
      ),
      createLog(
        id: 'log-3',
        entryTime: DateTime(2026, 10, 20),
        location: '沖縄本島 万座毛',
        marineLife: ['アオウミガメ', 'マンタ', 'ジンベエザメ'],
      ),
    ]);
  });

  group('GetMarineLifeSummaries UseCase (ユースケースUT)', () {
    test('パラメータなし（デフォルト）で全件が遭遇回数降順で取得できること', () async {
      // Arrange (準備): パラメータはデフォルト
      const params = MarineLifeFilterParams();

      // Act (実行)
      final result = await getMarineLifeSummariesUseCase(params);

      // Assert (検証):
      // アオウミガメ(2回), クマノミ(2回), マンタ(2回), ジンベエザメ(1回)
      expect(result.length, 4);
      expect(result[0].encounterCount, 2);
      expect(result[1].encounterCount, 2);
      expect(result[2].encounterCount, 2);
      expect(result[3].name, 'ジンベエザメ');
      expect(result[3].encounterCount, 1);
    });

    test('名前検索キーワードで生物を正しく絞り込めること（ひらがな入力にも対応）', () async {
      // Arrange (準備): 「うみがめ」で平仮名検索
      const params = MarineLifeFilterParams(query: 'うみがめ');

      // Act (実行)
      final result = await getMarineLifeSummariesUseCase(params);

      // Assert (検証)
      expect(result.length, 1);
      expect(result.first.name, 'アオウミガメ');
    });

    test('場所名検索キーワードで該当する生物を絞り込めること', () async {
      // Arrange (準備): 場所名「万座毛」で検索
      const params = MarineLifeFilterParams(query: '万座毛');

      // Act (実行)
      final result = await getMarineLifeSummariesUseCase(params);

      // Assert (検証): 万座毛で出会った生物（アオウミガメ、マンタ、ジンベエザメ）
      expect(result.length, 3);
      final names = result.map((r) => r.name).toList();
      expect(names, containsAll(['アオウミガメ', 'マンタ', 'ジンベエザメ']));
    });

    test('出現月フィルターで指定月に出会った生物のみに絞り込めること', () async {
      // Arrange (準備): 7月（month = 7）でフィルター
      const params = MarineLifeFilterParams(month: 7);

      // Act (実行)
      final result = await getMarineLifeSummariesUseCase(params);

      // Assert (検証): 7月のlog-1で出会った「アオウミガメ」と「クマノミ」
      expect(result.length, 2);
      final names = result.map((r) => r.name).toList();
      expect(names, containsAll(['アオウミガメ', 'クマノミ']));
      expect(names, isNot(contains('ジンベエザメ')));
    });

    test('ソート順「直近に遭遇した順」が正しく機能すること', () async {
      // Arrange (準備): 直近遭遇順 (recentlyEncountered)
      // 遭遇日: log-3 (10/20) > log-2 (8/15) > log-1 (7/10)
      // ジンベエザメ: 10/20
      // マンタ: 10/20
      // アオウミガメ: 10/20
      // クマノミ: 8/15
      const params = MarineLifeFilterParams(
        sortOrder: MarineLifeSortOrder.recentlyEncountered,
      );

      // Act (実行)
      final result = await getMarineLifeSummariesUseCase(params);

      // Assert (検証): 最後のアイテムがクマノミ（最新が8/15）
      expect(result.length, 4);
      expect(result.last.name, 'クマノミ');
    });
  });
}
