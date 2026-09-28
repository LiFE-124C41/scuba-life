import '../../domain/entities/dive_schedule.dart';
import '../../domain/repositories/dive_schedule_repository.dart';

class InMemoryDiveScheduleRepository implements DiveScheduleRepository {
  final List<DiveSchedule> _items = [
    DiveSchedule(
      id: 'sch-1',
      title: '伊豆海洋公園 ファンダイビング',
      eventDate: DateTime.now().add(const Duration(days: 7)),
      destination: '伊豆海洋公園 (IOP)',
      diveShop: 'オーシャンダイブショップ',
      plannedDivesCount: 2,
      memo: 'ポスト前で集合写真撮影予定。ドライスーツ着用。',
    ),
    DiveSchedule(
      id: 'sch-2',
      title: '沖縄・慶良間諸島ボートトリップ',
      eventDate: DateTime.now().add(const Duration(days: 30)),
      destination: '座間味島周辺',
      diveShop: 'ケラマダイブサービス',
      plannedDivesCount: 3,
      memo: 'ウミガメポイントとドリフトダイビング予定。ドリフトマーカー必須。',
    ),
  ];

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async {
    return _items;
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
