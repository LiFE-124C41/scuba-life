import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_schedule.dart';
import '../domain/repositories/dive_schedule_repository.dart';

/// 予定情報（持ち物チェック状態含む）を更新するユースケース
class UpdateDiveSchedule implements UseCase<void, DiveSchedule> {
  final DiveScheduleRepository _repository;

  UpdateDiveSchedule(this._repository);

  @override
  Future<void> call(DiveSchedule schedule) async {
    await _repository.updateSchedule(schedule);
  }
}
