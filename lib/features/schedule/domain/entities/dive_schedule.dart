/// ダイビング予定（トリップ/ツアー）のエンティティ
class DiveSchedule {
  final String id;
  final String title;
  final DateTime eventDate;
  final String destination;
  final String? spotId;
  final double? latitude;
  final double? longitude;
  final String diveShop;
  final int plannedDivesCount;
  final String memo;
  /// 機材管理からチェック（準備完了）された機材ID一覧
  final List<String> checkedGearIds;
  /// 今回の予定に持参する機材ID一覧（nullの場合は全機材が持参対象）
  final List<String>? targetGearIds;

  DiveSchedule({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.destination,
    this.spotId,
    this.latitude,
    this.longitude,
    required this.diveShop,
    this.plannedDivesCount = 2,
    this.memo = '',
    this.checkedGearIds = const [],
    this.targetGearIds,
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
    if (latitude != null && (latitude! < -90.0 || latitude! > 90.0)) {
      throw ArgumentError('緯度は-90から90の範囲である必要があります。');
    }
    if (longitude != null && (longitude! < -180.0 || longitude! > 180.0)) {
      throw ArgumentError('経度は-180から180の範囲である必要があります。');
    }
  }

  /// 指定した機材がチェック済みかどうかを判定
  bool isGearChecked(String gearId) => checkedGearIds.contains(gearId);

  /// 指定した機材が今回の予定の持参対象かどうかを判定（targetGearIdsがnullの場合はすべて持参対象）
  bool isGearTarget(String gearId) {
    if (targetGearIds == null) return true;
    return targetGearIds!.contains(gearId);
  }

  /// 登録済み全機材のうち、実際に持参対象となる機材ID一覧を計算
  List<String> effectiveTargetGearIds(List<String> allRegisteredGearIds) {
    if (targetGearIds == null) return allRegisteredGearIds;
    return allRegisteredGearIds.where((id) => targetGearIds!.contains(id)).toList();
  }

  /// チェック済み機材の件数
  int get checkedGearCount => checkedGearIds.length;

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
    String? spotId,
    double? latitude,
    double? longitude,
    String? diveShop,
    int? plannedDivesCount,
    String? memo,
    List<String>? checkedGearIds,
    List<String>? Function()? targetGearIds,
  }) {
    return DiveSchedule(
      id: id ?? this.id,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      destination: destination ?? this.destination,
      spotId: spotId ?? this.spotId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      diveShop: diveShop ?? this.diveShop,
      plannedDivesCount: plannedDivesCount ?? this.plannedDivesCount,
      memo: memo ?? this.memo,
      checkedGearIds: checkedGearIds ?? this.checkedGearIds,
      targetGearIds: targetGearIds != null ? targetGearIds() : this.targetGearIds,
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
          spotId == other.spotId &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          diveShop == other.diveShop &&
          plannedDivesCount == other.plannedDivesCount &&
          memo == other.memo &&
          _listEquals(checkedGearIds, other.checkedGearIds) &&
          _nullableListEquals(targetGearIds, other.targetGearIds);

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      eventDate.hashCode ^
      destination.hashCode ^
      spotId.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      diveShop.hashCode ^
      plannedDivesCount.hashCode ^
      memo.hashCode ^
      Object.hashAll(checkedGearIds) ^
      (targetGearIds != null ? Object.hashAll(targetGearIds!) : 0);

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _nullableListEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return _listEquals(a, b);
  }
}
