import '../../../core/usecase/usecase.dart';
import '../domain/repositories/dive_schedule_repository.dart';

class DeleteDiveSchedule implements UseCase<void, String> {
  final DiveScheduleRepository _repository;

  DeleteDiveSchedule(this._repository);

  @override
  Future<void> call(String id) async {
    await _repository.deleteSchedule(id);
  }
}
