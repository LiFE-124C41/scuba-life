import '../../../core/usecase/usecase.dart';
import '../domain/entities/dive_schedule.dart';
import '../domain/repositories/dive_schedule_repository.dart';

class GetDiveSchedules implements UseCase<List<DiveSchedule>, NoParams> {
  final DiveScheduleRepository _repository;

  GetDiveSchedules(this._repository);

  @override
  Future<List<DiveSchedule>> call(NoParams params) async {
    return await _repository.getUpcomingSchedules();
  }
}
