import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/dive_schedule.dart';
import '../../domain/repositories/dive_schedule_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_schedule_repository.dart';
import '../../usecase/add_dive_schedule.dart';
import '../../usecase/delete_dive_schedule.dart';
import '../../usecase/get_dive_schedules.dart';

/// リポジトリプロバイダー
final diveScheduleRepositoryProvider = Provider<DiveScheduleRepository>((ref) {
  return InMemoryDiveScheduleRepository();
});

/// ユースケースプロバイダー
final getDiveSchedulesUseCaseProvider = Provider<GetDiveSchedules>((ref) {
  final repo = ref.watch(diveScheduleRepositoryProvider);
  return GetDiveSchedules(repo);
});

final addDiveScheduleUseCaseProvider = Provider<AddDiveSchedule>((ref) {
  final repo = ref.watch(diveScheduleRepositoryProvider);
  return AddDiveSchedule(repo);
});

final deleteDiveScheduleUseCaseProvider = Provider<DeleteDiveSchedule>((ref) {
  final repo = ref.watch(diveScheduleRepositoryProvider);
  return DeleteDiveSchedule(repo);
});

/// カレンダーおよび予定一覧の状態クラス
class ScheduleCalendarState {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<DiveSchedule> schedules;
  final bool isLoading;
  final Object? error;

  const ScheduleCalendarState({
    required this.focusedMonth,
    required this.selectedDate,
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleCalendarState copyWith({
    DateTime? focusedMonth,
    DateTime? selectedDate,
    List<DiveSchedule>? schedules,
    bool? isLoading,
    Object? error,
  }) {
    return ScheduleCalendarState(
      focusedMonth: focusedMonth ?? this.focusedMonth,
      selectedDate: selectedDate ?? this.selectedDate,
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// 選択されている日付の予定一覧
  List<DiveSchedule> get selectedDateSchedules {
    return schedules.where((s) => s.isSameDay(selectedDate)).toList();
  }

  /// 指定した日付に予定が存在するか
  bool hasScheduleOn(DateTime date) {
    return schedules.any((s) => s.isSameDay(date));
  }

  /// 指定した日付の予定件数
  int scheduleCountOn(DateTime date) {
    return schedules.where((s) => s.isSameDay(date)).length;
  }
}

/// カレンダーおよび予定管理のコントローラー
class ScheduleCalendarNotifier extends Notifier<ScheduleCalendarState> {
  @override
  ScheduleCalendarState build() {
    final now = DateTime.now();
    Future.microtask(() => loadSchedules());
    return ScheduleCalendarState(
      focusedMonth: DateTime(now.year, now.month, 1),
      selectedDate: now,
      isLoading: true,
    );
  }

  GetDiveSchedules get _getDiveSchedules => ref.read(getDiveSchedulesUseCaseProvider);
  AddDiveSchedule get _addDiveSchedule => ref.read(addDiveScheduleUseCaseProvider);
  DeleteDiveSchedule get _deleteDiveSchedule => ref.read(deleteDiveScheduleUseCaseProvider);

  /// 予定一覧の取得
  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await _getDiveSchedules(const NoParams());
      state = state.copyWith(
        schedules: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// 日付選択
  void selectDate(DateTime date) {
    final newFocusedMonth =
        (date.year != state.focusedMonth.year || date.month != state.focusedMonth.month)
            ? DateTime(date.year, date.month, 1)
            : state.focusedMonth;
    state = state.copyWith(
      selectedDate: date,
      focusedMonth: newFocusedMonth,
    );
  }

  /// 前月へ移動
  void previousMonth() {
    state = state.copyWith(
      focusedMonth: DateTime(state.focusedMonth.year, state.focusedMonth.month - 1, 1),
    );
  }

  /// 次月へ移動
  void nextMonth() {
    state = state.copyWith(
      focusedMonth: DateTime(state.focusedMonth.year, state.focusedMonth.month + 1, 1),
    );
  }

  /// 今日の日付と月に移動
  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(
      focusedMonth: DateTime(now.year, now.month, 1),
      selectedDate: now,
    );
  }

  /// 予定追加
  Future<void> addSchedule(DiveSchedule schedule) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _addDiveSchedule(schedule);
      await loadSchedules();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 予定削除
  Future<void> deleteSchedule(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _deleteDiveSchedule(id);
      await loadSchedules();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}

/// カレンダーコントローラープロバイダー
final scheduleCalendarProvider =
    NotifierProvider<ScheduleCalendarNotifier, ScheduleCalendarState>(() {
  return ScheduleCalendarNotifier();
});
