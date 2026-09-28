import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/domain/repositories/gear_repository.dart';
import 'package:scuba_life/features/my_gear/interface/controllers/gear_controller.dart';

/// テスト用モックリポジトリ
class MockGearRepository implements GearRepository {
  final List<GearItem> items = [];

  @override
  Future<List<GearItem>> getAllGear() async => List.from(items);

  @override
  Future<GearItem?> getGearById(String id) async =>
      items.where((g) => g.id == id).firstOrNull;

  @override
  Future<void> saveGear(GearItem gear) async {
    final index = items.indexWhere((g) => g.id == gear.id);
    if (index >= 0) {
      items[index] = gear;
    } else {
      items.add(gear);
    }
  }

  @override
  Future<void> deleteGear(String id) async {
    items.removeWhere((g) => g.id == id);
  }
}

void main() {
  late MockGearRepository mockRepo;
  late ProviderContainer container;

  final sampleGear1 = GearItem(
    id: 'gear-1',
    name: 'レギュレーター APEKS',
    category: GearCategory.regulator,
    purchaseDate: DateTime(2025, 1, 1),
    overhaulIntervalMonths: 12,
  );

  final sampleGear2 = GearItem(
    id: 'gear-2',
    name: 'BCD SCUBAPRO',
    category: GearCategory.bcd,
    purchaseDate: DateTime(2025, 2, 1),
    overhaulIntervalMonths: 12,
  );

  setUp(() {
    mockRepo = MockGearRepository();
    container = ProviderContainer(
      overrides: [
        gearRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('GearListNotifier Controller Tests', () {
    test('【loadGear】初期化およびloadGear呼び出しで機材リストが正しくロードされること', () async {
      // Arrange
      mockRepo.items.addAll([sampleGear1, sampleGear2]);

      // Act
      await container.read(gearListNotifierProvider.notifier).loadGear();
      final state = container.read(gearListNotifierProvider);

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.allItems.length, equals(2));
      expect(state.allItems.map((g) => g.id), containsAll(['gear-1', 'gear-2']));
    });

    test('【setCategoryFilter】カテゴリーフィルター変更時、filteredItemsが正しく絞り込まれること', () async {
      // Arrange
      mockRepo.items.addAll([sampleGear1, sampleGear2]);
      await container.read(gearListNotifierProvider.notifier).loadGear();

      // Act: レギュレーターで絞り込み
      container.read(gearListNotifierProvider.notifier).setCategoryFilter(GearCategory.regulator);
      var state = container.read(gearListNotifierProvider);

      // Assert
      expect(state.selectedCategory, equals(GearCategory.regulator));
      expect(state.filteredItems.length, equals(1));
      expect(state.filteredItems.first.category, equals(GearCategory.regulator));

      // Act: フィルター解除
      container.read(gearListNotifierProvider.notifier).setCategoryFilter(null);
      state = container.read(gearListNotifierProvider);

      // Assert: 全件表示に戻ること
      expect(state.selectedCategory, isNull);
      expect(state.filteredItems.length, equals(2));
    });

    test('【saveGear / deleteGear】機材の保存と削除が状態に正しく反映されること', () async {
      // Arrange
      await container.read(gearListNotifierProvider.notifier).loadGear();
      expect(container.read(gearListNotifierProvider).allItems, isEmpty);

      // Act: 追加
      await container.read(gearListNotifierProvider.notifier).saveGear(sampleGear1);

      // Assert
      expect(container.read(gearListNotifierProvider).allItems.length, equals(1));
      expect(container.read(gearListNotifierProvider).allItems.first.id, equals('gear-1'));

      // Act: 削除
      await container.read(gearListNotifierProvider.notifier).deleteGear('gear-1');

      // Assert
      expect(container.read(gearListNotifierProvider).allItems, isEmpty);
    });

    test('【recordOverhaul】オーバーホール完了を記録すると、状態内の機材情報が更新されること', () async {
      // Arrange: 期限切れ状態のレギュレーターを登録
      final overdue = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2024, 1, 1),
        divesSinceOverhaul: 80,
      );
      mockRepo.items.add(overdue);
      await container.read(gearListNotifierProvider.notifier).loadGear();

      // Act: OH完了記録
      final now = DateTime.now();
      await container.read(gearListNotifierProvider.notifier).recordOverhaul(
            gearId: 'gear-1',
            overhaulDate: now,
            memo: 'ショップOH完了',
          );
      final state = container.read(gearListNotifierProvider);

      // Assert
      final updated = state.allItems.firstWhere((g) => g.id == 'gear-1');
      expect(updated.lastOverhaulDate, equals(now));
      expect(updated.divesSinceOverhaul, equals(0));
      expect(updated.memo, contains('ショップOH完了'));
      expect(updated.calculateStatus(now), equals(OverhaulStatus.good));
    });
  });
}
