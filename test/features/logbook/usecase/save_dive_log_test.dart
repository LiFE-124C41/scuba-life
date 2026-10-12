import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/usecase/get_dive_logs.dart';
import 'package:scuba_life/features/logbook/usecase/save_dive_log.dart';

/// テスト用モック（Mock/Fake）リポジトリ
///
/// 外部ストレージやDBへの依存を切り離し、メモリ上で状態を管理して振る舞いを検証する。
class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs = [];
  bool saveLogCalled = false;

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
    saveLogCalled = true;
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
  late SaveDiveLog saveDiveLogUseCase;
  late GetDiveLogs getDiveLogsUseCase;

  setUp(() {
    mockRepository = MockDiveLogRepository();
    saveDiveLogUseCase = SaveDiveLog(mockRepository);
    getDiveLogsUseCase = GetDiveLogs(mockRepository);
  });

  group('Logbook UseCases Tests', () {
    final sampleLog1 = DiveLog(
      id: 'log-1',
      entryTime: DateTime(2026, 9, 20, 10, 0),
      exitTime: DateTime(2026, 9, 20, 10, 45),
      maxDepthMeter: 18.0,
      avgDepthMeter: 11.0,
      startPressureBar: 200,
      endPressureBar: 60,
      location: '伊豆海洋公園',
    );

    final sampleLog2 = DiveLog(
      id: 'log-2',
      entryTime: DateTime(2026, 9, 25, 11, 0), // より新しい日時
      exitTime: DateTime(2026, 9, 25, 11, 50),
      maxDepthMeter: 22.0,
      avgDepthMeter: 13.0,
      startPressureBar: 200,
      endPressureBar: 50,
      location: '雲見',
    );

    test('【SaveDiveLog】ログ保存ユースケース実行時、リポジトリに正しくログが追加されること', () async {
      // Arrange
      expect(mockRepository.saveLogCalled, isFalse);

      // Act
      await saveDiveLogUseCase(sampleLog1);

      // Assert
      expect(mockRepository.saveLogCalled, isTrue);
      expect(mockRepository.logs.length, equals(1));
      expect(mockRepository.logs.first.id, equals('log-1'));
    });

    test('【GetDiveLogs】ログ一覧取得ユースケース実行時、エントリー日時の降順（最新順）で取得できること', () async {
      // Arrange: 過去ログ（log-1）と最新ログ（log-2）を保存
      mockRepository.logs.add(sampleLog1);
      mockRepository.logs.add(sampleLog2);

      // Act
      final result = await getDiveLogsUseCase(const NoParams());

      // Assert: 最新の log-2 が先頭に来ていること
      expect(result.length, equals(2));
      expect(result[0].id, equals('log-2'));
      expect(result[1].id, equals('log-1'));
    });
  });
}
