/// ダイビングログのエンティティ（ドメインモデル）
///
/// 外部フレームワークに一切依存しないPure Dartクラス。
class DiveLog {
  final String id;
  final DateTime entryTime;
  final DateTime exitTime;
  final double maxDepthMeter; // 最大水深 (m)
  final double avgDepthMeter; // 平均水深 (m)
  final double startPressureBar; // 開始気圧 (bar)
  final double endPressureBar; // 終了気圧 (bar)
  final double tankVolumeLiter; // タンク容量 (L, 標準は10Lまたは12L)
  final String location; // ポイント名
  final String notes; // メモ

  DiveLog({
    required this.id,
    required this.entryTime,
    required this.exitTime,
    required this.maxDepthMeter,
    required this.avgDepthMeter,
    required this.startPressureBar,
    required this.endPressureBar,
    this.tankVolumeLiter = 10.0,
    required this.location,
    this.notes = '',
  }) {
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
}
