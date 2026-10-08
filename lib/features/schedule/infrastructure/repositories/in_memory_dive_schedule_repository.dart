import '../../domain/entities/dive_schedule.dart';
import '../../domain/repositories/dive_schedule_repository.dart';

class InMemoryDiveScheduleRepository implements DiveScheduleRepository {
  final List<DiveSchedule> _items = [];

  InMemoryDiveScheduleRepository({List<DiveSchedule>? initialSchedules}) {
    if (initialSchedules != null) {
      _items.addAll(initialSchedules);
    } else {
      _initializeDefaults();
    }
  }

  void _initializeDefaults() {
    _items.addAll([
      DiveSchedule(
        id: 'sch-1',
        title: '伊豆海洋公園 ファンダイビング',
        eventDate: DateTime.now().add(const Duration(days: 2)),
        destination: '伊豆海洋公園 (IOP)',
        spotId: 'spot-iop-1',
        latitude: 34.8906,
        longitude: 139.1361,
        diveShop: 'オーシャンダイブショップ',
        plannedDivesCount: 2,
        memo: 'ポスト前で集合写真撮影予定。水中ポストへの投函ハガキ持参。',
      ),
      DiveSchedule(
        id: 'sch-2',
        title: '大瀬崎 湾内＆先端 ビーチダイブ',
        eventDate: DateTime.now().add(const Duration(days: 9)),
        destination: '大瀬崎 湾内',
        spotId: 'spot-osezaki-1',
        latitude: 35.0308,
        longitude: 138.7903,
        diveShop: '駿河ダイビングクラブ',
        plannedDivesCount: 2,
        memo: 'マクロ生物・ミジンベニハゼ観察。マクロレンズ準備。',
      ),
      DiveSchedule(
        id: 'sch-3',
        title: '沖縄・慶良間諸島ボートトリップ',
        eventDate: DateTime.now().add(const Duration(days: 20)),
        destination: '慶良間諸島・北浜(ニシバマ)',
        spotId: 'spot-kerama-1',
        latitude: 26.2083,
        longitude: 127.2889,
        diveShop: 'ケラマダイブサービス',
        plannedDivesCount: 3,
        memo: 'ウミガメポイントとドリフトダイビング予定。ドリフトマーカー必須。',
      ),
    ]);
  }

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async {
    return List.unmodifiable(_items);
  }

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
