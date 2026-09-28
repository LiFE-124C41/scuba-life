import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/domain/repositories/dive_log_repository.dart';
import 'package:scuba_life/features/logbook/interface/controllers/dive_log_controller.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/domain/repositories/gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';

/// テスト用モックログリポジトリ
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

/// テスト用モック機材リポジトリ
class MockGearRepository implements GearRepository {
  final List<GearItem> items = [];

  @override
  Future<List<GearItem>> getAllGear() async => List.from(items);

  @override
  Future<GearItem?> getGearById(String id) async =>
      items.where((i) => i.id == id).firstOrNull;

  @override
  Future<void> saveGear(GearItem item) async {
    final index = items.indexWhere((g) => g.id == item.id);
    if (index >= 0) {
      items[index] = item;
    } else {
      items.add(item);
    }
  }

  @override
  Future<void> deleteGear(String id) async {
    items.removeWhere((i) => i.id == id);
  }
}

void main() {
  group('DiveLogListNotifier Riverpod Controller Tests', () {
    late MockDiveLogRepository mockRepo;
    late MockGearRepository mockGearRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockDiveLogRepository();
      mockGearRepo = MockGearRepository();

      // Arrange: ProviderContainerでリポジトリの依存関係をモックに差し替え (DI)
      container = ProviderContainer(
        overrides: [
          diveLogRepositoryProvider.overrideWithValue(mockRepo),
          gearRepositoryProvider.overrideWithValue(mockGearRepo),
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

    test('【deleteLog】ログを削除すると一覧から除外され、紐付く機材のダイブ本数が自動で減算（巻き戻し）されること', () async {
      // Arrange: 機材（潜水本数 10本）と、その機材を使用したログを準備
      final gear = GearItem(
        id: 'gear-reg-1',
        name: 'Legend MBS',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 1, 1),
        divesSinceOverhaul: 10,
      );
      await mockGearRepo.saveGear(gear);

      // 機材Notifierの状態を初期化
      container.read(gearListNotifierProvider);

      final logWithGear = DiveLog(
        id: 'log-delete-target',
        entryTime: DateTime(2026, 9, 28, 10, 0),
        exitTime: DateTime(2026, 9, 28, 10, 45),
        maxDepthMeter: 20.0,
        avgDepthMeter: 12.0,
        startPressureBar: 200,
        endPressureBar: 50,
        location: '伊豆海洋公園',
        selectedGearIds: ['gear-reg-1'],
      );
      await container.read(diveLogListProvider.notifier).addLog(logWithGear);

      var currentLogs = container.read(diveLogListProvider).value!;
      expect(currentLogs.any((l) => l.id == 'log-delete-target'), isTrue);

      // Act: deleteLog を実行
      await container.read(diveLogListProvider.notifier).deleteLog('log-delete-target');

      // Assert 1: ログ一覧から削除されていること
      final remainingLogs = container.read(diveLogListProvider).value!;
      expect(remainingLogs.any((l) => l.id == 'log-delete-target'), isFalse);

      // Assert 2: 紐付いていた機材のダイブ本数が 10 -> 9 にデクリメント（巻き戻し）されていること
      final updatedGear = await mockGearRepo.getGearById('gear-reg-1');
      expect(updatedGear, isNotNull);
      expect(updatedGear!.divesSinceOverhaul, equals(9));
    });
  });
}

