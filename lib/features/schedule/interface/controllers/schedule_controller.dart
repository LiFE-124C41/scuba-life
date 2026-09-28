import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_schedule.dart';
import '../../domain/repositories/dive_schedule_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_schedule_repository.dart';
import '../../usecase/get_dive_schedules.dart';
import '../../../../core/usecase/usecase.dart';

final diveScheduleRepositoryProvider = Provider<DiveScheduleRepository>((ref) {
  return InMemoryDiveScheduleRepository();
});

final getDiveSchedulesUseCaseProvider = Provider<GetDiveSchedules>((ref) {
  final repo = ref.watch(diveScheduleRepositoryProvider);
  return GetDiveSchedules(repo);
});

final diveScheduleListProvider =
    FutureProvider<List<DiveSchedule>>((ref) async {
  final getSchedules = ref.watch(getDiveSchedulesUseCaseProvider);
  return await getSchedules(const NoParams());
});
