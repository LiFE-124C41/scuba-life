import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/infrastructure/repositories/firestore_schedule_repository.dart';

void main() {
  group('FirestoreScheduleRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreScheduleRepository repository;

    final testSchedule = DiveSchedule(
      id: 'sch-001',
      title: '西伊豆・大瀬崎ファンダイブ',
      eventDate: DateTime(2026, 11, 1),
      destination: '大瀬崎',
      spotId: 'spot-osezaki-1',
      latitude: 35.0308,
      longitude: 138.7903,
      diveShop: '大瀬館マリンサービス',
      plannedDivesCount: 2,
      memo: '朝7時集合、ドライスーツ準備',
      checkedGearIds: const ['gear-001'],
      targetGearIds: const ['gear-001', 'gear-002'],
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreScheduleRepository(
        userId: 'test-user-123',
        firestore: fakeFirestore,
      );
    });

    test('addSchedule & getUpcomingSchedules: 予定が保存され昇順で取得できること', () async {
      // Act
      await repository.addSchedule(testSchedule);
      final schedules = await repository.getUpcomingSchedules();

      // Assert
      expect(schedules.length, equals(1));
      final fetched = schedules.first;
      expect(fetched.id, equals('sch-001'));
      expect(fetched.title, equals('西伊豆・大瀬崎ファンダイブ'));
      expect(fetched.destination, equals('大瀬崎'));
      expect(fetched.plannedDivesCount, equals(2));
      expect(fetched.checkedGearIds, contains('gear-001'));
      expect(fetched.targetGearIds, containsAll(['gear-001', 'gear-002']));
    });

    test('updateSchedule: 予定の内容が更新されること', () async {
      // Arrange
      await repository.addSchedule(testSchedule);

      // Act
      final updated = testSchedule.copyWith(
        title: '西伊豆・大瀬崎 3ダイブに変更',
        plannedDivesCount: 3,
        checkedGearIds: const ['gear-001', 'gear-002'],
      );
      await repository.updateSchedule(updated);
      final schedules = await repository.getUpcomingSchedules();

      // Assert
      expect(schedules.length, equals(1));
      expect(schedules.first.title, equals('西伊豆・大瀬崎 3ダイブに変更'));
      expect(schedules.first.plannedDivesCount, equals(3));
      expect(schedules.first.checkedGearIds, containsAll(['gear-001', 'gear-002']));
    });

    test('deleteSchedule: 予定が削除されること', () async {
      // Arrange
      await repository.addSchedule(testSchedule);

      // Act
      await repository.deleteSchedule('sch-001');
      final schedules = await repository.getUpcomingSchedules();

      // Assert
      expect(schedules, isEmpty);
    });
  });
}
