import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/usecase/delete_dive_log.dart';

/// テスト用モック（Mock/Fake）リポジトリ
class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> logs = [];
  String? deletedLogId;

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
    deletedLogId = id;
    logs.removeWhere((l) => l.id == id);
  }
}

void main() {
  late MockDiveLogRepository mockRepository;
  late DeleteDiveLog deleteDiveLogUseCase;

  setUp(() {
    mockRepository = MockDiveLogRepository();
    deleteDiveLogUseCase = DeleteDiveLog(mockRepository);
  });

  group('DeleteDiveLog UseCase Tests', () {
    final sampleLog1 = DiveLog(
      id: 'log-1',
      entryTime: DateTime(2026, 9, 20, 10, 0),
      exitTime: DateTime(2026, 9, 20, 10, 45),
      maxDepthMeter: 18.0,
      avgDepthMeter: 11.0,
      startPressureBar: 200,
      endPressureBar: 60,
      location: '伊豆海洋公園',
      selectedGearIds: ['gear-reg-1', 'gear-comp-1'],
    );

    final sampleLog2 = DiveLog(
      id: 'log-2',
      entryTime: DateTime(2026, 9, 25, 11, 0),
      exitTime: DateTime(2026, 9, 25, 11, 50),
      maxDepthMeter: 22.0,
      avgDepthMeter: 13.0,
      startPressureBar: 200,
      endPressureBar: 50,
      location: '雲見',
    );

    test('【DeleteDiveLog】指定IDのログがリポジトリから削除されること', () async {
      // Arrange: 2件のログが存在する状態を準備
      mockRepository.logs.addAll([sampleLog1, sampleLog2]);
      expect(mockRepository.logs.length, equals(2));

      // Act: log-1 を削除
      await deleteDiveLogUseCase('log-1');

      // Assert: log-1 が削除され、log-2 のみが残っていること
      expect(mockRepository.deletedLogId, equals('log-1'));
      expect(mockRepository.logs.length, equals(1));
      expect(mockRepository.logs.first.id, equals('log-2'));
    });

    test('【DeleteDiveLog】存在しないIDを指定しても例外が発生しないこと', () async {
      // Arrange
      mockRepository.logs.add(sampleLog1);

      // Act & Assert: 存在しないIDを指定して実行しても安全に終了すること
      await expectLater(deleteDiveLogUseCase('non-existent-id'), completes);
      expect(mockRepository.logs.length, equals(1));
    });
  });
}
