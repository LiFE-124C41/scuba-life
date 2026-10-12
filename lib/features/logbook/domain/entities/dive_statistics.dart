import 'dive_log.dart';

/// ダイバーの統計・スキル指標エンティティ（ドメインモデル）
///
/// 初めて訪れるダイビングサービスやインストラクターに、
/// 自身の経験値やブランク期間、スキル適性を的確に提示するための統計情報を集約するPure Dartクラス。
class DiveStatistics {
  /// 総ダイブ本数
  final int totalDives;

  /// 累計潜水時間（分）
  final int totalBottomTimeMinutes;

  /// 平均潜水時間（分）
  final double avgBottomTimeMinutes;

  /// 最大経験水深 (m)
  final double maxDepthMeter;

  /// 平均最大水深 (m)
  final double avgMaxDepthMeter;

  /// 平均水面空気消費率 (SAC: L/min)
  final double? avgSacRate;

  /// 最終潜水日
  final DateTime? lastDiveDate;

  /// 最終潜水日からの経過日数（ブランク日数）
  final int? daysSinceLastDive;

  /// ブランクダイバー判定（目安: 半年以上/180日以上未潜水）
  final bool isBlankDiver;

  /// ボートダイビング本数
  final int boatDiveCount;

  /// ビーチダイビング本数
  final int beachDiveCount;

  /// その他エントリー本数
  final int otherEntryCount;

  /// 潮流経験マップ (キー: "なし", "弱", "中", "強" など, 値: 経験本数)
  final Map<String, int> currentExperienceMap;

  /// 直近の潜水ログ（最新順・最大3件）
  final List<DiveLog> recentLogs;

  const DiveStatistics({
    required this.totalDives,
    required this.totalBottomTimeMinutes,
    required this.avgBottomTimeMinutes,
    required this.maxDepthMeter,
    required this.avgMaxDepthMeter,
    this.avgSacRate,
    this.lastDiveDate,
    this.daysSinceLastDive,
    required this.isBlankDiver,
    required this.boatDiveCount,
    required this.beachDiveCount,
    required this.otherEntryCount,
    required this.currentExperienceMap,
    required this.recentLogs,
  });

  /// 空の統計データ
  factory DiveStatistics.empty() {
    return const DiveStatistics(
      totalDives: 0,
      totalBottomTimeMinutes: 0,
      avgBottomTimeMinutes: 0.0,
      maxDepthMeter: 0.0,
      avgMaxDepthMeter: 0.0,
      avgSacRate: null,
      lastDiveDate: null,
      daysSinceLastDive: null,
      isBlankDiver: false,
      boatDiveCount: 0,
      beachDiveCount: 0,
      otherEntryCount: 0,
      currentExperienceMap: {},
      recentLogs: [],
    );
  }

  /// ログ一覧から統計指標を算出するファクトリコンストラクタ
  ///
  /// [referenceDate] は経過日数（ブランク日数）を計算するための基準日時。
  /// テスト時に日時の固定化を行う際にも活用可能。
  factory DiveStatistics.fromLogs(
    List<DiveLog> logs, {
    DateTime? referenceDate,
  }) {
    if (logs.isEmpty) {
      return DiveStatistics.empty();
    }

    final totalDives = logs.length;

    // 日付・エントリー時間順に降順ソートしたログリスト
    final sortedLogs = List<DiveLog>.from(logs)
      ..sort((a, b) => b.entryTime.compareTo(a.entryTime));

    // 累計潜水時間
    int totalBottomTimeMinutes = 0;
    // 最大水深
    double maxDepth = 0.0;
    // 各ダイブの最大水深の合計
    double sumMaxDepth = 0.0;
    // SACレート集計用
    double sumSacRate = 0.0;
    int validSacCount = 0;

    // エントリー種別
    int boatCount = 0;
    int beachCount = 0;
    int otherCount = 0;

    // 潮流経験
    final Map<String, int> currentMap = {
      'なし': 0,
      '弱': 0,
      '中': 0,
      '強': 0,
    };

    for (final log in sortedLogs) {
      // 潜水時間
      final bt = log.bottomTimeMinutes;
      if (bt > 0) {
        totalBottomTimeMinutes += bt;
      }

      // 水深
      if (log.maxDepthMeter > maxDepth) {
        maxDepth = log.maxDepthMeter;
      }
      sumMaxDepth += log.maxDepthMeter;

      // SACレート（有効な値のみ集計）
      final sac = log.calculateSacRate();
      if (sac > 0.0 && !sac.isNaN && !sac.isInfinite) {
        sumSacRate += sac;
        validSacCount++;
      }

      // エントリー
      final method = log.entryMethod.trim();
      if (method.contains('ボート')) {
        boatCount++;
      } else if (method.contains('ビーチ')) {
        beachCount++;
      } else {
        otherCount++;
      }

      // 潮流
      final current = log.underwaterCurrent.trim();
      if (currentMap.containsKey(current)) {
        currentMap[current] = currentMap[current]! + 1;
      } else if (current.isNotEmpty) {
        currentMap[current] = (currentMap[current] ?? 0) + 1;
      }
    }

    // 平均値の計算
    final avgBottomTimeMinutes =
        totalDives > 0 ? (totalBottomTimeMinutes / totalDives) : 0.0;
    final avgMaxDepthMeter =
        totalDives > 0 ? (sumMaxDepth / totalDives) : 0.0;
    final avgSacRate =
        validSacCount > 0 ? (sumSacRate / validSacCount) : null;

    // 最終潜水日 & ブランク計算
    final latestLog = sortedLogs.first;
    final lastDiveDate = latestLog.entryTime;
    final now = referenceDate ?? DateTime.now();

    // 経過日数（0時0分で日付単位の差分を正確に算出）
    final today = DateTime(now.year, now.month, now.day);
    final diveDay = DateTime(
      lastDiveDate.year,
      lastDiveDate.month,
      lastDiveDate.day,
    );
    final daysDifference = today.difference(diveDay).inDays;
    final daysSinceLastDive = daysDifference >= 0 ? daysDifference : 0;

    // 180日（約半年）以上潜っていない場合はブランクと判定
    final isBlankDiver = daysSinceLastDive >= 180;

    // 直近3本のログ
    final recentLogs = sortedLogs.take(3).toList();

    return DiveStatistics(
      totalDives: totalDives,
      totalBottomTimeMinutes: totalBottomTimeMinutes,
      avgBottomTimeMinutes: avgBottomTimeMinutes,
      maxDepthMeter: maxDepth,
      avgMaxDepthMeter: avgMaxDepthMeter,
      avgSacRate: avgSacRate,
      lastDiveDate: lastDiveDate,
      daysSinceLastDive: daysSinceLastDive,
      isBlankDiver: isBlankDiver,
      boatDiveCount: boatCount,
      beachDiveCount: beachCount,
      otherEntryCount: otherCount,
      currentExperienceMap: currentMap,
      recentLogs: recentLogs,
    );
  }

  /// 累計潜水時間を「○○時間 ○○分」形式でフォーマットして返却
  String get totalBottomTimeFormatted {
    final hours = totalBottomTimeMinutes ~/ 60;
    final minutes = totalBottomTimeMinutes % 60;
    if (hours > 0) {
      return '$hours時間 $minutes分';
    }
    return '$minutes分';
  }

  /// ボートダイビング比率 (0.0〜1.0)
  double get boatRatio =>
      totalDives > 0 ? (boatDiveCount / totalDives) : 0.0;

  /// ビーチダイビング比率 (0.0〜1.0)
  double get beachRatio =>
      totalDives > 0 ? (beachDiveCount / totalDives) : 0.0;

  /// ブランク状態のテキスト表現（インストラクター向けステータス）
  String get statusBadgeLabel {
    if (totalDives == 0) return '未経験';
    if (daysSinceLastDive == null) return '記録なし';
    if (daysSinceLastDive! <= 30) return 'アクティブ（好調）';
    if (daysSinceLastDive! <= 90) return '標準';
    if (daysSinceLastDive! <= 180) return '軽度ブランク';
    return 'ブランクあり（要リフレッシュ）';
  }
}
