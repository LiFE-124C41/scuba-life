import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/infrastructure/repositories/firestore_gear_repository.dart';

void main() {
  group('FirestoreGearRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreGearRepository repository;

    final testGear = GearItem(
      id: 'gear-001',
      name: 'マイレギュレーター',
      category: GearCategory.regulator,
      brand: 'Apeks',
      model: 'XTX200',
      serialNumber: 'SN-123456',
      purchaseDate: DateTime(2025, 4, 1),
      lastOverhaulDate: DateTime(2026, 4, 1),
      divesSinceOverhaul: 25,
      overhaulIntervalMonths: 12,
      overhaulIntervalDives: 100,
      requiresOverhaul: true,
      memo: '2026年4月に定期オーバーホール実施済',
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreGearRepository(
        userId: 'test-user-123',
        firestore: fakeFirestore,
      );
    });

    test('saveGear & getGearById: 機材が保存され、カテゴリーやOH情報が正しく復元されること', () async {
      // Act
      await repository.saveGear(testGear);
      final fetched = await repository.getGearById('gear-001');

      // Assert
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('gear-001'));
      expect(fetched.name, equals('マイレギュレーター'));
      expect(fetched.category, equals(GearCategory.regulator));
      expect(fetched.brand, equals('Apeks'));
      expect(fetched.model, equals('XTX200'));
      expect(fetched.divesSinceOverhaul, equals(25));
      expect(fetched.overhaulIntervalMonths, equals(12));
      expect(fetched.overhaulIntervalDives, equals(100));
      expect(fetched.requiresOverhaul, isTrue);
      expect(fetched.memo, equals('2026年4月に定期オーバーホール実施済'));
    });

    test('getAllGear: 登録された機材一覧が取得できること', () async {
      // Arrange
      await repository.saveGear(testGear);
      final bcd = GearItem(
        id: 'gear-002',
        name: 'マイBCD',
        category: GearCategory.bcd,
        brand: 'Scubapro',
        purchaseDate: DateTime(2025, 5, 1),
      );
      await repository.saveGear(bcd);

      // Act
      final list = await repository.getAllGear();

      // Assert
      expect(list.length, equals(2));
      expect(list.any((g) => g.id == 'gear-001'), isTrue);
      expect(list.any((g) => g.id == 'gear-002'), isTrue);
    });

    test('deleteGear: 指定IDの機材が削除されること', () async {
      // Arrange
      await repository.saveGear(testGear);

      // Act
      await repository.deleteGear('gear-001');
      final fetched = await repository.getGearById('gear-001');

      // Assert
      expect(fetched, isNull);
    });
  });
}
