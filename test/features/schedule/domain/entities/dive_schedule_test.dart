import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';

void main() {
  group('DiveSchedule Entity & Domain Logic Tests', () {
    final baseDate = DateTime(2026, 9, 30, 10, 30);

    test('正常系: 有効な値でインスタンスが生成できること', () {
      // Arrange & Act
      final schedule = DiveSchedule(
        id: 'sch-101',
        title: '伊豆海洋公園 ファンダイブ',
        eventDate: baseDate,
        destination: '伊豆海洋公園',
        diveShop: 'オーシャンダイブ',
        plannedDivesCount: 2,
        memo: 'ポスト前集合',
      );

      // Assert
      expect(schedule.id, 'sch-101');
      expect(schedule.title, '伊豆海洋公園 ファンダイブ');
      expect(schedule.eventDate, baseDate);
      expect(schedule.destination, '伊豆海洋公園');
      expect(schedule.diveShop, 'オーシャンダイブ');
      expect(schedule.plannedDivesCount, 2);
      expect(schedule.memo, 'ポスト前集合');
    });

    test('isSameDay: 時刻が異なっていても同じ日付であれば true を返すこと', () {
      // Arrange
      final schedule = DiveSchedule(
        id: 'sch-1',
        title: 'テスト予定',
        eventDate: DateTime(2026, 9, 30, 8, 0),
        destination: '大瀬崎',
        diveShop: 'ショップA',
      );

      // Act & Assert
      // 同日の異なる時刻
      expect(schedule.isSameDay(DateTime(2026, 9, 30, 23, 59)), isTrue);
      // 別の日
      expect(schedule.isSameDay(DateTime(2026, 9, 29, 8, 0)), isFalse);
      // 別の月
      expect(schedule.isSameDay(DateTime(2026, 10, 30, 8, 0)), isFalse);
      // 別の年
      expect(schedule.isSameDay(DateTime(2025, 9, 30, 8, 0)), isFalse);
    });

    test('copyWith: 指定したフィールドのみ更新され新しいインスタンスが生成されること', () {
      // Arrange
      final original = DiveSchedule(
        id: 'sch-1',
        title: '元のタイトル',
        eventDate: baseDate,
        destination: '元の場所',
        diveShop: '元のショップ',
        plannedDivesCount: 1,
        memo: '元のメモ',
      );

      // Act
      final updated = original.copyWith(
        title: '新しいタイトル',
        plannedDivesCount: 3,
      );

      // Assert
      expect(updated.id, original.id);
      expect(updated.title, '新しいタイトル');
      expect(updated.plannedDivesCount, 3);
      expect(updated.destination, original.destination);
      expect(updated.memo, original.memo);
    });

    test('checkedGearIds: 機材チェック状態の保持・判定・copyWithが正しく動作すること', () {
      // Arrange
      final schedule = DiveSchedule(
        id: 'sch-check-1',
        title: '持ち物チェック予定',
        eventDate: baseDate,
        destination: '大瀬崎',
        diveShop: 'ショップA',
        checkedGearIds: ['gear-1', 'gear-2'],
      );

      // Act & Assert
      expect(schedule.checkedGearCount, 2);
      expect(schedule.isGearChecked('gear-1'), isTrue);
      expect(schedule.isGearChecked('gear-2'), isTrue);
      expect(schedule.isGearChecked('gear-3'), isFalse);

      // copyWithでチェック解除
      final uncheckOne = schedule.copyWith(checkedGearIds: ['gear-1']);
      expect(uncheckOne.checkedGearCount, 1);
      expect(uncheckOne.isGearChecked('gear-2'), isFalse);

      // 等価性比較
      final sameSchedule = DiveSchedule(
        id: 'sch-check-1',
        title: '持ち物チェック予定',
        eventDate: baseDate,
        destination: '大瀬崎',
        diveShop: 'ショップA',
        checkedGearIds: ['gear-1', 'gear-2'],
      );
      expect(schedule, equals(sameSchedule));
    });

    test('targetGearIds: 持参対象機材の判定・除外・effectiveTargetGearIdsが正しく動作すること', () {
      // Arrange 1: targetGearIds が null（デフォルト：全機材が対象）
      final defaultSchedule = DiveSchedule(
        id: 'sch-target-null',
        title: '全機材持参予定',
        eventDate: baseDate,
        destination: '大瀬崎',
        diveShop: 'ショップA',
      );

      expect(defaultSchedule.targetGearIds, isNull);
      expect(defaultSchedule.isGearTarget('gear-1'), isTrue);
      expect(defaultSchedule.isGearTarget('gear-2'), isTrue);
      expect(
        defaultSchedule.effectiveTargetGearIds(['gear-1', 'gear-2', 'gear-3']),
        ['gear-1', 'gear-2', 'gear-3'],
      );

      // Arrange 2: targetGearIds を指定（特定機材のみ持参）
      final customSchedule = defaultSchedule.copyWith(
        targetGearIds: () => ['gear-1', 'gear-3'],
      );

      expect(customSchedule.targetGearIds, ['gear-1', 'gear-3']);
      expect(customSchedule.isGearTarget('gear-1'), isTrue);
      expect(customSchedule.isGearTarget('gear-2'), isFalse);
      expect(customSchedule.isGearTarget('gear-3'), isTrue);
      expect(
        customSchedule.effectiveTargetGearIds(['gear-1', 'gear-2', 'gear-3']),
        ['gear-1', 'gear-3'],
      );

      // copyWithで targetGearIds を null にリセット
      final resetSchedule = customSchedule.copyWith(
        targetGearIds: () => null,
      );
      expect(resetSchedule.targetGearIds, isNull);
      expect(resetSchedule.isGearTarget('gear-2'), isTrue);
    });

    group('異常系バリデーションテスト', () {
      test('タイトルが空文字または空白のみの場合、ArgumentErrorがスローされること', () {
        // Arrange, Act & Assert
        expect(
          () => DiveSchedule(
            id: 'err-1',
            title: '   ',
            eventDate: baseDate,
            destination: '大瀬崎',
            diveShop: 'ショップ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('目的地が空文字または空白のみの場合、ArgumentErrorがスローされること', () {
        // Arrange, Act & Assert
        expect(
          () => DiveSchedule(
            id: 'err-2',
            title: 'ファンダイブ',
            eventDate: baseDate,
            destination: '',
            diveShop: 'ショップ',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('予定ダイビング本数が1未満の場合、ArgumentErrorがスローされること', () {
        // Arrange, Act & Assert
        expect(
          () => DiveSchedule(
            id: 'err-3',
            title: 'ファンダイブ',
            eventDate: baseDate,
            destination: '大瀬崎',
            diveShop: 'ショップ',
            plannedDivesCount: 0,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
