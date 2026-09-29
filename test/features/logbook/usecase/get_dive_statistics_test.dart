import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/usecase/get_dive_statistics.dart';

/// テスト用モック（Mock/Fake）リポジトリ
///
/// 外部DBやインフラ層の依存を切り離し、ユースケース層の集計連携ロジックを独立して検証する。
class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs = [];

  @override
  Future<List<DiveLog>> getAllLogs() async {
    return List.from(logs);
  }

  @override
  Future<DiveLog?> getLogById(String id) async {
    return logs.where((l) => l.id == id).firstOrNull;
  }

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
  late GetDiveStatistics getDiveStatisticsUseCase;

  setUp(() {
    mockRepository = MockDiveLogRepository();
    getDiveStatisticsUseCase = GetDiveStatistics(mockRepository);
  });

  group('GetDiveStatistics UseCase Tests', () {
    test('リポジトリからログが取得され、正確な統計情報が生成・返却されること', () async {
      // Arrange (準備)
      final sampleLog = DiveLog(
        id: 'log-stat-1',
        entryTime: DateTime(2026, 9, 15, 9, 30),
        exitTime: DateTime(2026, 9, 15, 10, 15), // 45分
        location: '雲見 牛着岩',
        maxDepthMeter: 24.5,
        avgDepthMeter: 14.0,
        startPressureBar: 200,
        endPressureBar: 50,
        tankVolumeLiter: 10.0,
        entryMethod: 'ボート',
        underwaterCurrent: '中',
        rating: 5,
      );
      mockRepository.logs.add(sampleLog);

      // Act (実行)
      final result = await getDiveStatisticsUseCase(const NoParams());

      // Assert (検証)
      expect(result.totalDives, 1);
      expect(result.totalBottomTimeMinutes, 45);
      expect(result.maxDepthMeter, 24.5);
      expect(result.avgMaxDepthMeter, 24.5);
      expect(result.boatDiveCount, 1);
      expect(result.beachDiveCount, 0);
      expect(result.currentExperienceMap['中'], 1);
      expect(result.recentLogs.length, 1);
      expect(result.recentLogs.first.id, 'log-stat-1');
    });

    test('リポジトリにログが存在しない場合、空の統計情報が返却されること', () async {
      // Arrange (準備): リポジトリは空
      mockRepository.logs.clear();

      // Act (実行)
      final result = await getDiveStatisticsUseCase(const NoParams());

      // Assert (検証)
      expect(result.totalDives, 0);
      expect(result.totalBottomTimeMinutes, 0);
      expect(result.maxDepthMeter, 0.0);
      expect(result.recentLogs, isEmpty);
    });
  });
}
