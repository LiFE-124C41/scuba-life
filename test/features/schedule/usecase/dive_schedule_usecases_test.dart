import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/domain/repositories/dive_schedule_repository.dart';
import 'package:scuba_life/features/schedule/usecase/add_dive_schedule.dart';
import 'package:scuba_life/features/schedule/usecase/delete_dive_schedule.dart';
import 'package:scuba_life/features/schedule/usecase/get_dive_schedules.dart';

/// テスト用のフェイクリポジトリ
/// 外部依存なしでインメモリにデータを保持し、各ユースケースの入出力を検証する
class FakeDiveScheduleRepository implements DiveScheduleRepository {
  final List<DiveSchedule> _items = [];

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<void> addSchedule(DiveSchedule schedule) async {
    _items.add(schedule);
  }

  @override
  Future<void> deleteSchedule(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

void main() {
  late FakeDiveScheduleRepository fakeRepo;
  late GetDiveSchedules getDiveSchedules;
  late AddDiveSchedule addDiveSchedule;
  late DeleteDiveSchedule deleteDiveSchedule;

  setUp(() {
    fakeRepo = FakeDiveScheduleRepository();
    getDiveSchedules = GetDiveSchedules(fakeRepo);
    addDiveSchedule = AddDiveSchedule(fakeRepo);
    deleteDiveSchedule = DeleteDiveSchedule(fakeRepo);
  });

  group('DiveSchedule UseCases Tests', () {
    test('【AddDiveSchedule & GetDiveSchedules】予定の追加と取得が正しく行われること', () async {
      // Arrange
      final schedule1 = DiveSchedule(
        id: 'sch-1',
        title: '伊豆海洋公園',
        eventDate: DateTime(2026, 9, 30),
        destination: 'IOP',
        diveShop: 'ショップA',
        plannedDivesCount: 2,
      );
      final schedule2 = DiveSchedule(
        id: 'sch-2',
        title: '大瀬崎',
        eventDate: DateTime(2026, 10, 5),
        destination: '湾内',
        diveShop: 'ショップB',
        plannedDivesCount: 3,
      );

      // Act
      await addDiveSchedule(schedule1);
      await addDiveSchedule(schedule2);
      final result = await getDiveSchedules(const NoParams());

      // Assert
      expect(result.length, 2);
      expect(result[0].title, '伊豆海洋公園');
      expect(result[1].title, '大瀬崎');
    });

    test('【DeleteDiveSchedule】指定IDの予定が正常に削除されること', () async {
      // Arrange
      final schedule = DiveSchedule(
        id: 'target-id',
        title: '削除対象の予定',
        eventDate: DateTime(2026, 9, 30),
        destination: '宮古島',
        diveShop: 'アイランドダイブ',
      );
      await addDiveSchedule(schedule);
      final beforeDelete = await getDiveSchedules(const NoParams());
      expect(beforeDelete.length, 1);

      // Act
      await deleteDiveSchedule('target-id');
      final afterDelete = await getDiveSchedules(const NoParams());

      // Assert
      expect(afterDelete.isEmpty, isTrue);
    });
  });
}
