import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/domain/repositories/dive_schedule_repository.dart';
import 'package:scuba_life/features/schedule/interface/controllers/schedule_controller.dart';

/// テスト用のモックリポジトリ
class MockScheduleRepository implements DiveScheduleRepository {
  final List<DiveSchedule> _items = [
    DiveSchedule(
      id: 'sch-1',
      title: 'テスト予定1',
      eventDate: DateTime(2026, 9, 20),
      destination: '伊豆海洋公園',
      diveShop: 'ショップA',
      plannedDivesCount: 2,
    ),
    DiveSchedule(
      id: 'sch-2',
      title: 'テスト予定2',
      eventDate: DateTime(2026, 9, 20),
      destination: '富戸',
      diveShop: 'ショップB',
      plannedDivesCount: 1,
    ),
    DiveSchedule(
      id: 'sch-3',
      title: 'テスト予定3（来月）',
      eventDate: DateTime(2026, 10, 15),
      destination: '慶良間諸島',
      diveShop: 'ショップC',
      plannedDivesCount: 3,
    ),
  ];

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async => List.unmodifiable(_items);

  @override
  Future<void> addSchedule(DiveSchedule schedule) async {
    _items.add(schedule);
  }

  @override
  Future<void> updateSchedule(DiveSchedule schedule) async {
    final index = _items.indexWhere((item) => item.id == schedule.id);
    if (index != -1) {
      _items[index] = schedule;
    } else {
      _items.add(schedule);
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    _items.removeWhere((item) => item.id == id);
  }
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        diveScheduleRepositoryProvider.overrideWithValue(MockScheduleRepository()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ScheduleCalendarNotifier Controller Tests', () {
    test('初期化時: 初期データがロードされ、予定リストが設定されること', () async {
      // Arrange & Act
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();
      final state = container.read(scheduleCalendarProvider);

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.schedules.length, 3);
    });

    test('selectDate: 選択日付が正しく更新され、月が異なる場合はfocusedMonthも同期されること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      final newDate = DateTime(2026, 10, 15);

      // Act
      notifier.selectDate(newDate);
      final state = container.read(scheduleCalendarProvider);

      // Assert
      expect(state.selectedDate, newDate);
      expect(state.focusedMonth.year, 2026);
      expect(state.focusedMonth.month, 10);
    });

    test('selectedDateSchedules: 選択された日付の予定のみが抽出されること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();

      // Act
      notifier.selectDate(DateTime(2026, 9, 20));
      final state = container.read(scheduleCalendarProvider);

      // Assert
      expect(state.selectedDateSchedules.length, 2);
      expect(state.selectedDateSchedules[0].title, 'テスト予定1');
      expect(state.selectedDateSchedules[1].title, 'テスト予定2');
    });

    test('hasScheduleOn / scheduleCountOn: 日付別の予定有無・件数が正しく判定されること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();
      final state = container.read(scheduleCalendarProvider);

      // Act & Assert
      // 9/20 には2件
      expect(state.hasScheduleOn(DateTime(2026, 9, 20)), isTrue);
      expect(state.scheduleCountOn(DateTime(2026, 9, 20)), 2);

      // 9/21 には予定なし
      expect(state.hasScheduleOn(DateTime(2026, 9, 21)), isFalse);
      expect(state.scheduleCountOn(DateTime(2026, 9, 21)), 0);
    });

    test('月送り機能: previousMonth と nextMonth で focusedMonth が前後に移動すること', () {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      notifier.selectDate(DateTime(2026, 8, 1));

      // Act: 次月
      notifier.nextMonth();
      var state = container.read(scheduleCalendarProvider);
      expect(state.focusedMonth.month, 9);

      // Act: 前月
      notifier.previousMonth();
      state = container.read(scheduleCalendarProvider);
      expect(state.focusedMonth.month, 8);
    });

    test('addSchedule / deleteSchedule: 予定の追加と削除が状態に正しく反映されること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();

      final newSchedule = DiveSchedule(
        id: 'new-100',
        title: '新規予定',
        eventDate: DateTime(2026, 11, 1),
        destination: '久米島',
        diveShop: 'アイランドサービス',
      );

      // Act: 追加
      await notifier.addSchedule(newSchedule);
      var state = container.read(scheduleCalendarProvider);
      expect(state.schedules.length, 4);
      expect(state.hasScheduleOn(DateTime(2026, 11, 1)), isTrue);

      // Act: 削除
      await notifier.deleteSchedule('new-100');
      state = container.read(scheduleCalendarProvider);
      expect(state.schedules.length, 3);
      expect(state.hasScheduleOn(DateTime(2026, 11, 1)), isFalse);
    });

    test('【toggleGearCheck & toggleAllGearCheck】機材チェック状態がトグルおよび全選択/全解除できること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();

      // 初期状態: sch-1のcheckedGearIdsは空
      var sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, isEmpty);

      // Act 1: gear-1 をチェックON
      await notifier.toggleGearCheck('sch-1', 'gear-1');
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, ['gear-1']);
      expect(sched.isGearChecked('gear-1'), isTrue);

      // Act 2: gear-2 をチェックON
      await notifier.toggleGearCheck('sch-1', 'gear-2');
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, ['gear-1', 'gear-2']);

      // Act 3: gear-1 をチェックOFF（トグル）
      await notifier.toggleGearCheck('sch-1', 'gear-1');
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, ['gear-2']);

      // Act 4: 全選択
      await notifier.toggleAllGearCheck('sch-1', ['gear-1', 'gear-2', 'gear-3'], true);
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds.length, 3);

      // Act 5: 全解除
      await notifier.toggleAllGearCheck('sch-1', ['gear-1', 'gear-2', 'gear-3'], false);
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, isEmpty);
    });

    test('【updateTargetGearIds】持参対象機材が更新され、除外された機材のチェックが自動解除されること', () async {
      // Arrange
      final notifier = container.read(scheduleCalendarProvider.notifier);
      await notifier.loadSchedules();

      // sch-1 に gear-1, gear-2 をチェック状態にしておく
      await notifier.toggleGearCheck('sch-1', 'gear-1');
      await notifier.toggleGearCheck('sch-1', 'gear-2');
      var sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');
      expect(sched.checkedGearIds, ['gear-1', 'gear-2']);
      expect(sched.targetGearIds, isNull);

      // Act 1: 持参対象機材を ['gear-1', 'gear-3'] に限定（gear-2 は持参対象外）
      await notifier.updateTargetGearIds('sch-1', ['gear-1', 'gear-3']);
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');

      // Assert 1: targetGearIds が更新され、除外された gear-2 が checkedGearIds から自動削除されていること
      expect(sched.targetGearIds, ['gear-1', 'gear-3']);
      expect(sched.checkedGearIds, ['gear-1']);

      // Act 2: targetGearIds を null（全機材持参）に戻す
      await notifier.updateTargetGearIds('sch-1', null);
      sched = container.read(scheduleCalendarProvider).schedules.firstWhere((s) => s.id == 'sch-1');

      // Assert 2: targetGearIds が null に戻り、checkedGearIds はそのまま維持されること
      expect(sched.targetGearIds, isNull);
      expect(sched.checkedGearIds, ['gear-1']);
    });
  });
}
