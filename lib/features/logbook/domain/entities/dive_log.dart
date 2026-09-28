/// ダイビングログのエンティティ（ドメインモデル）
///
/// 外部フレームワークに一切依存しないPure Dartクラス。
class DiveLog {
  final String id;
  final String? scheduleId; // 関連するダイビング予定のID (オプショナル)
  final DateTime date; // 日付
  final DateTime entryTime; // 潜水開始時刻
  final DateTime exitTime; // 潜水終了時刻
  final String location; // ポイント名
  final String diveCenter; // 主催センター / ショップ名
  final int rating; // 5段階評価 (1〜5)
  final String divePurpose; // ダイビング目的 (ファン、講習・教育 等)
  final String entryMethod; // エントリー (ビーチ、ボート 等)
  final String waterArea; // 水域 (海洋、湖 等)
  final String waterType; // 水質 (海水、淡水 等)

  // 深度・気圧・物理実績
  final double maxDepthMeter; // 最大水深 (m)
  final double avgDepthMeter; // 平均水深 (m)
  final double startPressureBar; // 開始気圧 (bar)
  final double endPressureBar; // 終了気圧 (bar)
  final double tankVolumeLiter; // シリンダー容量 (L)
  final String cylinderMaterial; // シリンダー材質 (スチール、アルミ 等)
  final double? weightKg; // ウェイト量 (kg)

  // 計画データ
  final double? plannedDepthMeter; // 計画水深 (m)
  final int? plannedDurationMinutes; // 計画時間 (分)
  final double? plannedReservePressureBar; // 計画残圧 (bar)

  // 環境・海況・潮汐
  final String weather; // 天気
  final double? airTemp; // 気温 (℃)
  final double? waterTempMin; // 最低水温 (℃)
  final double? waterTempMax; // 最高水温 (℃)
  final double? visibilityMeter; // 透明度 (m)
  final String underwaterCurrent; // 水中の流れ (なし、弱、中、強 等)
  final String surfaceCurrent; // 水面の流れ・波浪 (穏やか、うねり 等)
  final String tideType; // 潮流タイプ (大潮、中潮、小潮、長潮、若潮 等)
  final String? highTideTime1; // 満潮時間1 (例: "06:30")
  final String? lowTideTime1; // 干潮時間1 (例: "12:45")
  final String? highTideTime2; // 満潮時間2 (例: "18:50")
  final String? lowTideTime2; // 干潮時間2 (例: "00:15")

  // メンバー・機材・生物・メモ
  final List<String> buddies; // バディ名（複数）
  final List<String> marineLife; // 出会った生物
  final String equipment; // 使用した機材
  final String notes; // メモ

  DiveLog({
    required this.id,
    this.scheduleId,
    DateTime? date,
    required this.entryTime,
    required this.exitTime,
    required this.location,
    this.diveCenter = '',
    this.rating = 3,
    this.divePurpose = 'ファンダイビング',
    this.entryMethod = 'ボート',
    this.waterArea = '海洋',
    this.waterType = '海水',
    required this.maxDepthMeter,
    required this.avgDepthMeter,
    required this.startPressureBar,
    required this.endPressureBar,
    this.tankVolumeLiter = 10.0,
    this.cylinderMaterial = 'スチール',
    this.weightKg,
    this.plannedDepthMeter,
    this.plannedDurationMinutes,
    this.plannedReservePressureBar,
    this.weather = '晴れ',
    this.airTemp,
    this.waterTempMin,
    this.waterTempMax,
    this.visibilityMeter,
    this.underwaterCurrent = 'なし',
    this.surfaceCurrent = '穏やか',
    this.tideType = '中潮',
    this.highTideTime1,
    this.lowTideTime1,
    this.highTideTime2,
    this.lowTideTime2,
    this.buddies = const [],
    this.marineLife = const [],
    this.equipment = '',
    this.notes = '',
  }) : date = date ?? DateTime(entryTime.year, entryTime.month, entryTime.day) {
    if (entryTime.isAfter(exitTime)) {
      throw ArgumentError('エントリー時間はエグジット時間より前である必要があります。');
    }
    if (maxDepthMeter < 0 || avgDepthMeter < 0) {
      throw ArgumentError('水深は0以上である必要があります。');
    }
    if (avgDepthMeter > maxDepthMeter) {
      throw ArgumentError('平均水深は最大水深以下である必要があります。');
    }
    if (startPressureBar < endPressureBar) {
      throw ArgumentError('開始気圧は終了気圧以上である必要があります。');
    }
    if (rating < 1 || rating > 5) {
      throw ArgumentError('評価は1〜5の間である必要があります。');
    }
    if (waterTempMin != null && waterTempMax != null && waterTempMin! > waterTempMax!) {
      throw ArgumentError('最低水温は最高水温以下である必要があります。');
    }
    if (weightKg != null && weightKg! < 0) {
      throw ArgumentError('ウェイトは0以上である必要があります。');
    }
  }

  /// 潜水時間（分）
  int get bottomTimeMinutes => exitTime.difference(entryTime).inMinutes;

  /// 消費気圧 (bar)
  double get consumedPressureBar => startPressureBar - endPressureBar;

  /// 水面空気消費率 (SAC: Surface Air Consumption) [L/min]
  /// 計算式: 消費空気量(L) / (潜水時間(分) * 平均環境圧(atm))
  /// 環境圧 = 1 + (平均水深 / 10)
  double calculateSacRate() {
    if (bottomTimeMinutes <= 0) return 0.0;
    final totalAirConsumedLiters = consumedPressureBar * tankVolumeLiter;
    final avgAtmosphere = 1.0 + (avgDepthMeter / 10.0);
    return totalAirConsumedLiters / (bottomTimeMinutes * avgAtmosphere);
  }

  DiveLog copyWith({
    String? id,
    String? scheduleId,
    DateTime? date,
    DateTime? entryTime,
    DateTime? exitTime,
    String? location,
    String? diveCenter,
    int? rating,
    String? divePurpose,
    String? entryMethod,
    String? waterArea,
    String? waterType,
    double? maxDepthMeter,
    double? avgDepthMeter,
    double? startPressureBar,
    double? endPressureBar,
    double? tankVolumeLiter,
    String? cylinderMaterial,
    double? weightKg,
    double? plannedDepthMeter,
    int? plannedDurationMinutes,
    double? plannedReservePressureBar,
    String? weather,
    double? airTemp,
    double? waterTempMin,
    double? waterTempMax,
    double? visibilityMeter,
    String? underwaterCurrent,
    String? surfaceCurrent,
    String? tideType,
    String? highTideTime1,
    String? lowTideTime1,
    String? highTideTime2,
    String? lowTideTime2,
    List<String>? buddies,
    List<String>? marineLife,
    String? equipment,
    String? notes,
  }) {
    return DiveLog(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      location: location ?? this.location,
      diveCenter: diveCenter ?? this.diveCenter,
      rating: rating ?? this.rating,
      divePurpose: divePurpose ?? this.divePurpose,
      entryMethod: entryMethod ?? this.entryMethod,
      waterArea: waterArea ?? this.waterArea,
      waterType: waterType ?? this.waterType,
      maxDepthMeter: maxDepthMeter ?? this.maxDepthMeter,
      avgDepthMeter: avgDepthMeter ?? this.avgDepthMeter,
      startPressureBar: startPressureBar ?? this.startPressureBar,
      endPressureBar: endPressureBar ?? this.endPressureBar,
      tankVolumeLiter: tankVolumeLiter ?? this.tankVolumeLiter,
      cylinderMaterial: cylinderMaterial ?? this.cylinderMaterial,
      weightKg: weightKg ?? this.weightKg,
      plannedDepthMeter: plannedDepthMeter ?? this.plannedDepthMeter,
      plannedDurationMinutes: plannedDurationMinutes ?? this.plannedDurationMinutes,
      plannedReservePressureBar: plannedReservePressureBar ?? this.plannedReservePressureBar,
      weather: weather ?? this.weather,
      airTemp: airTemp ?? this.airTemp,
      waterTempMin: waterTempMin ?? this.waterTempMin,
      waterTempMax: waterTempMax ?? this.waterTempMax,
      visibilityMeter: visibilityMeter ?? this.visibilityMeter,
      underwaterCurrent: underwaterCurrent ?? this.underwaterCurrent,
      surfaceCurrent: surfaceCurrent ?? this.surfaceCurrent,
      tideType: tideType ?? this.tideType,
      highTideTime1: highTideTime1 ?? this.highTideTime1,
      lowTideTime1: lowTideTime1 ?? this.lowTideTime1,
      highTideTime2: highTideTime2 ?? this.highTideTime2,
      lowTideTime2: lowTideTime2 ?? this.lowTideTime2,
      buddies: buddies ?? this.buddies,
      marineLife: marineLife ?? this.marineLife,
      equipment: equipment ?? this.equipment,
      notes: notes ?? this.notes,
    );
  }
}
