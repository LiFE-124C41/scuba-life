import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/domain/repositories/gear_repository.dart';
import 'package:scuba_life/features/my_gear/usecase/decrement_gear_dives.dart';

/// テスト用モック（Mock/Fake）リポジトリ
///
/// 外部DBやストレージに依存せず、インメモリで機材状態を保持し、
/// DecrementGearDives ユースケースの振る舞いを検証する。
class MockGearRepository implements GearRepository {
  final Map<String, GearItem> items = {};

  @override
  Future<List<GearItem>> getAllGear() async => items.values.toList();

  @override
  Future<GearItem?> getGearById(String id) async => items[id];

  @override
  Future<void> saveGear(GearItem gear) async {
    items[gear.id] = gear;
  }

  @override
  Future<void> deleteGear(String id) async {
    items.remove(id);
  }
}

void main() {
  late MockGearRepository mockRepository;
  late DecrementGearDives decrementGearDivesUseCase;

  setUp(() {
    mockRepository = MockGearRepository();
    decrementGearDivesUseCase = DecrementGearDives(mockRepository);
  });

  group('DecrementGearDives UseCase Tests', () {
    final now = DateTime.now();

    final gear1 = GearItem(
      id: 'gear-1',
      name: 'レギュレーター',
      category: GearCategory.regulator,
      purchaseDate: now,
      divesSinceOverhaul: 10,
    );

    final gear2 = GearItem(
      id: 'gear-2',
      name: 'BCD',
      category: GearCategory.bcd,
      purchaseDate: now,
      divesSinceOverhaul: 0,
    );

    test('【正常系】指定された複数機材IDのダイブ本数がそれぞれ-1されること', () async {
      // Arrange
      await mockRepository.saveGear(gear1);

      // Act: gear-1 をデクリメント
      await decrementGearDivesUseCase(['gear-1']);

      // Assert
      final updatedGear1 = await mockRepository.getGearById('gear-1');
      expect(updatedGear1?.divesSinceOverhaul, equals(9));
    });

    test('【下限ガード】ダイブ本数が0本の機材をデクリメントしても負数にならず0を維持すること', () async {
      // Arrange
      await mockRepository.saveGear(gear2); // 0本

      // Act
      await decrementGearDivesUseCase(['gear-2']);

      // Assert
      final updatedGear2 = await mockRepository.getGearById('gear-2');
      expect(updatedGear2?.divesSinceOverhaul, equals(0));
    });

    test('【重複排除】同一機材IDが複数渡されても、ダイブ本数は1回のみデクリメントされること', () async {
      // Arrange
      await mockRepository.saveGear(gear1); // 10本

      // Act: 同一IDを重複指定
      await decrementGearDivesUseCase(['gear-1', 'gear-1', 'gear-1']);

      // Assert: -1 のみ行われること
      final updatedGear1 = await mockRepository.getGearById('gear-1');
      expect(updatedGear1?.divesSinceOverhaul, equals(9));
    });

    test('【境界値・異常系】存在しない機材IDが含まれていても例外なく処理され、存在する機材のみ更新されること', () async {
      // Arrange
      await mockRepository.saveGear(gear1); // 10本

      // Act
      await decrementGearDivesUseCase(['gear-1', 'non-existing-id']);

      // Assert
      final updatedGear1 = await mockRepository.getGearById('gear-1');
      expect(updatedGear1?.divesSinceOverhaul, equals(9));
    });

    test('【空リスト】空のリストを渡した場合は何も行われないこと', () async {
      // Arrange
      await mockRepository.saveGear(gear1); // 10本

      // Act
      await decrementGearDivesUseCase([]);

      // Assert
      final updatedGear1 = await mockRepository.getGearById('gear-1');
      expect(updatedGear1?.divesSinceOverhaul, equals(10));
    });
  });
}
