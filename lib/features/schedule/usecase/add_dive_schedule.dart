import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_schedule.dart';
import '../domain/repositories/dive_schedule_repository.dart';

class AddDiveSchedule implements UseCase<void, DiveSchedule> {
  final DiveScheduleRepository _repository;

  AddDiveSchedule(this._repository);

  @override
  Future<void> call(DiveSchedule schedule) async {
    await _repository.addSchedule(schedule);
  }
}
