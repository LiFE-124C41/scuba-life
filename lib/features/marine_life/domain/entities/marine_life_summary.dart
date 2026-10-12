import '../../../logbook/domain/entities/dive_log.dart';

/// 生き物図鑑・遭遇サマリーのエンティティ（ドメインモデル）
///
/// ログブックに記録されたダイビングログ群から、
/// 出会った生物（marineLife）ごとに遭遇回数・出現月・場所・過去ログを集約するPure Dartクラス。
class MarineLifeSummary {
  /// 生物名（例: "アオウミガメ", "クマノミ", "マンタ"）
  final String name;

  /// 総遭遇回数（出会ったダイブログの本数）
  final int encounterCount;

  /// 出会った月の一覧（1〜12、昇順・重複なし）
  final List<int> months;

  /// 出会ったダイビングポイント・場所の一覧（重複なし）
  final List<String> locations;

  /// 最初に遭遇した日
  final DateTime? firstEncounterDate;

  /// 直近（最後）に遭遇した日
  final DateTime? lastEncounterDate;

  /// 遭遇した最深水深 (m)
  final double? maxDepthMeter;

  /// 遭遇したダイブログ一覧（最新順）
  final List<DiveLog> encounterLogs;

  const MarineLifeSummary({
    required this.name,
    required this.encounterCount,
    required this.months,
    required this.locations,
    this.firstEncounterDate,
    this.lastEncounterDate,
    this.maxDepthMeter,
    this.encounterLogs = const [],
  });

  /// 全ログブックデータから生物ごとのサマリーリストを生成・集約するファクトリメソッド
  factory MarineLifeSummary.fromLogs(List<DiveLog> logs) {
    throw UnimplementedError('個別サマリーではなく fromLogsList をご利用ください。');
  }

  /// ログ一覧から各生物のサマリー一覧を集計・生成する
  ///
  /// - 遭遇回数が多い順（同数の場合は名前の五十音順）にソートして返却
  /// - 各生物内のログは最新順にソート
  static List<MarineLifeSummary> fromLogsList(List<DiveLog> logs) {
    if (logs.isEmpty) return const [];

    // 生物名（正規化後） -> 遭遇したログ一覧のマップ
    final Map<String, List<DiveLog>> speciesLogsMap = {};

    for (final log in logs) {
      if (log.marineLife.isEmpty) continue;

      // 1つのログ内で同一生物が重複して記載されていた場合の二重カウントを防止
      final seenInThisLog = <String>{};

      for (final rawName in log.marineLife) {
        final trimmed = rawName.trim();
        if (trimmed.isEmpty) continue;
        if (seenInThisLog.contains(trimmed)) continue;

        seenInThisLog.add(trimmed);
        speciesLogsMap.putIfAbsent(trimmed, () => []).add(log);
      }
    }

    final List<MarineLifeSummary> summaries = [];

    for (final entry in speciesLogsMap.entries) {
      final name = entry.key;
      final matchedLogs = entry.value;

      // ログを最新順（entryTime降順）にソート
      final sortedLogs = List<DiveLog>.from(matchedLogs)
        ..sort((a, b) => b.entryTime.compareTo(a.entryTime));

      // 出現月（1〜12）の収集とソート
      final monthSet = <int>{};
      for (final l in sortedLogs) {
        monthSet.add(l.entryTime.month);
      }
      final sortedMonths = monthSet.toList()..sort();

      // 出会った場所の収集（空文字除外、重複排除）
      final locationList = <String>[];
      for (final l in sortedLogs) {
        final loc = l.location.trim();
        if (loc.isNotEmpty && !locationList.contains(loc)) {
          locationList.add(loc);
        }
      }

      // 最初と最後の遭遇日
      final lastDate = sortedLogs.first.entryTime;
      final firstDate = sortedLogs.last.entryTime;

      // 最大水深の算出
      double maxDepth = 0.0;
      for (final l in sortedLogs) {
        if (l.maxDepthMeter > maxDepth) {
          maxDepth = l.maxDepthMeter;
        }
      }

      summaries.add(
        MarineLifeSummary(
          name: name,
          encounterCount: sortedLogs.length,
          months: sortedMonths,
          locations: locationList,
          firstEncounterDate: firstDate,
          lastEncounterDate: lastDate,
          maxDepthMeter: maxDepth > 0 ? maxDepth : null,
          encounterLogs: sortedLogs,
        ),
      );
    }

    // デフォルト並び順: 遭遇回数の多い順、同数なら名前順
    summaries.sort((a, b) {
      final countComp = b.encounterCount.compareTo(a.encounterCount);
      if (countComp != 0) return countComp;
      return a.name.compareTo(b.name);
    });

    return summaries;
  }
}
