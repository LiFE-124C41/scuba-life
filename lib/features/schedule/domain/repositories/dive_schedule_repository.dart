import '../entities/dive_schedule.dart';

abstract class DiveScheduleRepository {
  Future<List<DiveSchedule>> getUpcomingSchedules();
  Future<void> addSchedule(DiveSchedule schedule);
  Future<void> deleteSchedule(String id);
}
