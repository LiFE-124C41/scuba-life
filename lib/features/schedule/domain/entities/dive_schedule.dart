/// ダイビング予定（トリップ/ツアー）のエンティティ
class DiveSchedule {
  final String id;
  final String title;
  final DateTime eventDate;
  final String destination;
  final String diveShop;
  final int plannedDivesCount;
  final String memo;

  DiveSchedule({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.destination,
    required this.diveShop,
    this.plannedDivesCount = 2,
    this.memo = '',
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('タイトルは必須です。');
    }
    if (destination.trim().isEmpty) {
      throw ArgumentError('目的地・ポイントは必須です。');
    }
    if (plannedDivesCount < 1) {
      throw ArgumentError('予定ダイビング本数は1本以上である必要があります。');
    }
  }

  /// 指定した日付と同じ日であるかどうかを判定（時刻は無視）
  bool isSameDay(DateTime date) {
    return eventDate.year == date.year &&
        eventDate.month == date.month &&
        eventDate.day == date.day;
  }

  DiveSchedule copyWith({
    String? id,
    String? title,
    DateTime? eventDate,
    String? destination,
    String? diveShop,
    int? plannedDivesCount,
    String? memo,
  }) {
    return DiveSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      destination: destination ?? this.destination,
      diveShop: diveShop ?? this.diveShop,
      plannedDivesCount: plannedDivesCount ?? this.plannedDivesCount,
      memo: memo ?? this.memo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiveSchedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          eventDate.year == other.eventDate.year &&
          eventDate.month == other.eventDate.month &&
          eventDate.day == other.eventDate.day &&
          destination == other.destination &&
          diveShop == other.diveShop &&
          plannedDivesCount == other.plannedDivesCount &&
          memo == other.memo;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      eventDate.hashCode ^
      destination.hashCode ^
      diveShop.hashCode ^
      plannedDivesCount.hashCode ^
      memo.hashCode;
}
