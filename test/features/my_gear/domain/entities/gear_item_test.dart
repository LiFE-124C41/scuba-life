import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';

void main() {
  group('GearItem Domain Entity Tests', () {
    final basePurchaseDate = DateTime(2025, 1, 1);

    test('【正常系】必須項目およびデフォルト値でインスタンスが生成できること', () {
      // Arrange & Act
      final gear = GearItem(
        id: 'gear-1',
        name: 'レギュレーター LEGEND',
        category: GearCategory.regulator,
        purchaseDate: basePurchaseDate,
      );

      // Assert
      expect(gear.id, equals('gear-1'));
      expect(gear.name, equals('レギュレーター LEGEND'));
      expect(gear.category, equals(GearCategory.regulator));
      expect(gear.requiresOverhaul, isTrue); // レギュレーターはデフォルトでOH対象
      expect(gear.overhaulIntervalMonths, equals(12));
      expect(gear.overhaulIntervalDives, equals(100));
      expect(gear.divesSinceOverhaul, equals(0));
    });

    test('【バリデーション】機材名が空の場合はArgumentErrorが発生すること', () {
      // Arrange, Act & Assert
      expect(
        () => GearItem(
          id: 'gear-1',
          name: '   ',
          category: GearCategory.regulator,
          purchaseDate: basePurchaseDate,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('【次回オーバーホール日】最終OH日がない場合は購入日基準、ある場合は最終OH日基準で加算されること', () {
      // Arrange (最終OH日なし -> 購入日2025/1/1 + 12ヶ月 = 2026/1/1)
      final gearWithoutOH = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 1, 1),
        overhaulIntervalMonths: 12,
      );

      // Act & Assert
      expect(
        gearWithoutOH.nextOverhaulDate,
        equals(DateTime(2026, 1, 1)),
      );

      // Arrange (最終OH日あり: 2025/6/15 + 12ヶ月 = 2026/6/15)
      final gearWithOH = gearWithoutOH.copyWith(
        lastOverhaulDate: DateTime(2025, 6, 15),
      );

      // Act & Assert
      expect(
        gearWithOH.nextOverhaulDate,
        equals(DateTime(2026, 6, 15)),
      );
    });

    test('【オーバーホール状態判定】OH対象外の場合は none となること', () {
      // Arrange
      final fin = GearItem(
        id: 'gear-fin',
        name: 'ミューフィン',
        category: GearCategory.maskSnorkelFin,
        purchaseDate: basePurchaseDate,
        requiresOverhaul: false,
      );

      // Act & Assert
      expect(fin.calculateStatus(), equals(OverhaulStatus.none));
    });

    test('【オーバーホール状態判定】期限まで30日以上・本数に余裕がある場合は good (良好) となること', () {
      // Arrange: 次回目安日が2026/6/1、現在日が2026/1/1（残り5ヶ月）
      final gear = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 6, 1),
        lastOverhaulDate: DateTime(2025, 6, 1),
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        divesSinceOverhaul: 20,
      );

      // Act
      final status = gear.calculateStatus(DateTime(2026, 1, 1));

      // Assert
      expect(status, equals(OverhaulStatus.good));
    });

    test('【オーバーホール状態判定】残り日数30日以内の場合は warning (まもなく) となること', () {
      // Arrange: 次回目安日が2026/1/15、現在日が2026/1/1（残り14日）
      final gear = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 1, 15),
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        divesSinceOverhaul: 30,
      );

      // Act
      final status = gear.calculateStatus(DateTime(2026, 1, 1));

      // Assert
      expect(status, equals(OverhaulStatus.warning));
    });

    test('【オーバーホール状態判定】残りダイブ本数10本以内の場合も warning (まもなく) となること', () {
      // Arrange: 日数は余裕があるが、92/100本（残り8本）
      final gear = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 6, 1),
        lastOverhaulDate: DateTime(2025, 6, 1),
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        divesSinceOverhaul: 92,
      );

      // Act
      final status = gear.calculateStatus(DateTime(2026, 1, 1));

      // Assert
      expect(status, equals(OverhaulStatus.warning));
    });

    test('【オーバーホール状態判定】期限日超過または規定ダイブ本数超過の場合は overdue (要オーバーホール) となること', () {
      // Arrange: 日数超過パターン
      final overdueByDate = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2024, 1, 1),
        overhaulIntervalMonths: 12,
        divesSinceOverhaul: 10,
      );

      // Act & Assert (現在日: 2026/1/1)
      expect(
        overdueByDate.calculateStatus(DateTime(2026, 1, 1)),
        equals(OverhaulStatus.overdue),
      );

      // Arrange: ダイブ本数超過パターン（105/100本）
      final overdueByDives = GearItem(
        id: 'gear-2',
        name: 'BCD',
        category: GearCategory.bcd,
        purchaseDate: DateTime(2025, 6, 1),
        lastOverhaulDate: DateTime(2025, 6, 1),
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        divesSinceOverhaul: 105,
      );

      // Act & Assert (現在日: 2025/10/1)
      expect(
        overdueByDives.calculateStatus(DateTime(2025, 10, 1)),
        equals(OverhaulStatus.overdue),
      );
    });

    test('【オーバーホール記録】recordOverhaul実行時、最終OH日が更新され、ダイブ本数が0にリセットされること', () {
      // Arrange
      final gear = GearItem(
        id: 'gear-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2024, 1, 1),
        lastOverhaulDate: DateTime(2024, 1, 1),
        divesSinceOverhaul: 85,
        memo: '初期メモ',
      );

      // Act
      final newOHDate = DateTime(2026, 9, 29);
      final updatedGear = gear.recordOverhaul(
        overhaulDate: newOHDate,
        additionalMemo: '1stステージOリング全交換',
      );

      // Assert
      expect(updatedGear.lastOverhaulDate, equals(newOHDate));
      expect(updatedGear.divesSinceOverhaul, equals(0));
      expect(updatedGear.memo, contains('初期メモ'));
      expect(updatedGear.memo, contains('1stステージOリング全交換'));
      expect(updatedGear.calculateStatus(newOHDate), equals(OverhaulStatus.good));
    });
  });
}
