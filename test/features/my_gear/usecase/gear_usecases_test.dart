import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/domain/repositories/gear_repository.dart';
import 'package:scuba_life/features/my_gear/usecase/delete_gear_item.dart';
import 'package:scuba_life/features/my_gear/usecase/get_gear_items.dart';
import 'package:scuba_life/features/my_gear/usecase/record_overhaul.dart';
import 'package:scuba_life/features/my_gear/usecase/save_gear_item.dart';

/// テスト用モック（Mock/Fake）リポジトリ
///
/// 外部ストレージやDBへの依存を切り離し、メモリ上で状態を管理して振る舞いを検証する。
class MockGearRepository implements GearRepository {
  final List<GearItem> items = [];
  bool saveGearCalled = false;
  bool deleteGearCalled = false;

  @override
  Future<List<GearItem>> getAllGear() async {
    return List.from(items);
  }

  @override
  Future<GearItem?> getGearById(String id) async {
    return items.where((g) => g.id == id).firstOrNull;
  }

  @override
  Future<void> saveGear(GearItem gear) async {
    saveGearCalled = true;
    final index = items.indexWhere((g) => g.id == gear.id);
    if (index >= 0) {
      items[index] = gear;
    } else {
      items.add(gear);
    }
  }

  @override
  Future<void> deleteGear(String id) async {
    deleteGearCalled = true;
    items.removeWhere((g) => g.id == id);
  }
}

void main() {
  late MockGearRepository mockRepository;
  late GetGearItems getGearItemsUseCase;
  late SaveGearItem saveGearItemUseCase;
  late DeleteGearItem deleteGearItemUseCase;
  late RecordOverhaul recordOverhaulUseCase;

  setUp(() {
    mockRepository = MockGearRepository();
    getGearItemsUseCase = GetGearItems(mockRepository);
    saveGearItemUseCase = SaveGearItem(mockRepository);
    deleteGearItemUseCase = DeleteGearItem(mockRepository);
    recordOverhaulUseCase = RecordOverhaul(mockRepository);
  });

  group('Gear UseCases Tests', () {
    final now = DateTime.now();

    final overdueGear = GearItem(
      id: 'gear-overdue',
      name: '期限切れレギュレーター',
      category: GearCategory.regulator,
      purchaseDate: now.subtract(const Duration(days: 500)),
      overhaulIntervalMonths: 12,
      divesSinceOverhaul: 120, // 本数・日数ともに超過
    );

    final goodGear = GearItem(
      id: 'gear-good',
      name: '点検直後BCD',
      category: GearCategory.bcd,
      purchaseDate: now.subtract(const Duration(days: 60)),
      overhaulIntervalMonths: 12,
      divesSinceOverhaul: 5,
    );

    final finNoOH = GearItem(
      id: 'gear-fin',
      name: 'フィン',
      category: GearCategory.maskSnorkelFin,
      purchaseDate: now.subtract(const Duration(days: 200)),
      requiresOverhaul: false,
    );

    test('【SaveGearItem】機材保存ユースケース実行時、リポジトリに機材が正しく追加・更新されること', () async {
      // Arrange
      expect(mockRepository.saveGearCalled, isFalse);

      // Act
      await saveGearItemUseCase(goodGear);

      // Assert
      expect(mockRepository.saveGearCalled, isTrue);
      expect(mockRepository.items.length, equals(1));
      expect(mockRepository.items.first.id, equals('gear-good'));
    });

    test('【DeleteGearItem】機材削除ユースケース実行時、指定したIDの機材がリポジトリから削除されること', () async {
      // Arrange
      mockRepository.items.addAll([goodGear, overdueGear]);
      expect(mockRepository.items.length, equals(2));

      // Act
      await deleteGearItemUseCase('gear-good');

      // Assert
      expect(mockRepository.deleteGearCalled, isTrue);
      expect(mockRepository.items.length, equals(1));
      expect(mockRepository.items.first.id, equals('gear-overdue'));
    });

    test('【GetGearItems】機材一覧取得ユースケース実行時、オーバーホール緊急度順（overdueが先頭）に並び替えて取得できること', () async {
      // Arrange: 良好な機材、OH対象外、期限超過機材をランダムな順序で登録
      mockRepository.items.add(goodGear);
      mockRepository.items.add(finNoOH);
      mockRepository.items.add(overdueGear);

      // Act
      final result = await getGearItemsUseCase(const NoParams());

      // Assert: overdue(期限切れ)が先頭に来ること
      expect(result.length, equals(3));
      expect(result[0].id, equals('gear-overdue'));
      expect(result[1].id, equals('gear-good'));
      expect(result[2].id, equals('gear-fin'));
    });

    test('【RecordOverhaul】オーバーホール実施記録ユースケース実行時、該当機材のOH日が更新されリセットされること', () async {
      // Arrange
      mockRepository.items.add(overdueGear);
      final ohDate = DateTime.now();

      // Act
      final updated = await recordOverhaulUseCase(
        RecordOverhaulParams(
          gearId: 'gear-overdue',
          overhaulDate: ohDate,
          memo: 'オーバーホール完了。工賃25,000円。',
        ),
      );

      // Assert
      expect(updated.lastOverhaulDate, equals(ohDate));
      expect(updated.divesSinceOverhaul, equals(0));
      expect(updated.memo, contains('オーバーホール完了'));

      final stored = await mockRepository.getGearById('gear-overdue');
      expect(stored?.lastOverhaulDate, equals(ohDate));
      expect(stored?.divesSinceOverhaul, equals(0));
    });

    test('【RecordOverhaul】存在しない機材IDを指定した場合、StateErrorがスローされること', () async {
      // Arrange & Act & Assert
      expect(
        () => recordOverhaulUseCase(
          RecordOverhaulParams(
            gearId: 'non-existing-gear',
            overhaulDate: DateTime.now(),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
