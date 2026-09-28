/// ダイビング予定（トリップ/ツアー）のエンティティ
class DiveSchedule {
  final String id;
  final String title;
  final DateTime eventDate;
  final String destination;
  final String diveShop;
  final int plannedDivesCount;
  final String memo;

  const DiveSchedule({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.destination,
    required this.diveShop,
    this.plannedDivesCount = 2,
    this.memo = '',
  });
}
