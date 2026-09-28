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
