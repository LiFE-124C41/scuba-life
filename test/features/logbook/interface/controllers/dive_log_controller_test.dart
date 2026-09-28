import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';

/// テスト用モックリポジトリ
class MockDiveLogRepository implements DiveLogRepository {
  final List<DiveLog> _storage = [];

  @override
  Future<List<DiveLog>> getAllLogs() async => List.from(_storage);

  @override
  Future<DiveLog?> getLogById(String id) async =>
      _storage.where((log) => log.id == id).firstOrNull;

  @override
  Future<void> saveLog(DiveLog log) async {
    _storage.removeWhere((l) => l.id == log.id);
    _storage.add(log);
  }

  @override
  Future<void> deleteLog(String id) async {
    _storage.removeWhere((l) => l.id == id);
  }
}

void main() {
  group('DiveLogListNotifier Riverpod Controller Tests', () {
    late MockDiveLogRepository mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockDiveLogRepository();

      // Arrange: ProviderContainerでリポジトリの依存関係をモックに差し替え (DI)
      container = ProviderContainer(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初期化時: 初期データがロードされてAsyncData状態となること', () async {
      // Arrange & Act
      final asyncLogs = await container.read(diveLogListProvider.future);

      // Assert
      expect(asyncLogs, isNotEmpty);
      expect(container.read(diveLogListProvider).hasValue, isTrue);
    });

    test('【addLog】新しいログを追加すると、状態が更新されて最新ログが一覧に含まれること', () async {
      // Arrange: 初期状態の読み込み完了を待機
      await container.read(diveLogListProvider.future);

      final newLog = DiveLog(
        id: 'new-log-999',
        entryTime: DateTime(2026, 9, 28, 14, 0),
        exitTime: DateTime(2026, 9, 28, 14, 45),
        maxDepthMeter: 24.5,
        avgDepthMeter: 15.0,
        startPressureBar: 200,
        endPressureBar: 60,
        location: '雲見・牛着岩',
        notes: '地形ダイビング。洞窟内のキンメモドキが圧巻。',
      );

      // Act: NotifierのaddLogメソッドを呼び出し
      await container.read(diveLogListProvider.notifier).addLog(newLog);
      final updatedLogs = container.read(diveLogListProvider).value!;

      // Assert: 新しいログが含まれていること
      expect(updatedLogs.any((l) => l.id == 'new-log-999'), isTrue);
      expect(updatedLogs.firstWhere((l) => l.id == 'new-log-999').location, equals('雲見・牛着岩'));
    });
  });
}
