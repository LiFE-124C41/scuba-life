import '../../../core/usecase/usecase.dart';
import '../../logbook/domain/repositories/dive_log_repository.dart';
import '../domain/entities/marine_life_summary.dart';

/// 生き物図鑑の並び替え種別
enum MarineLifeSortOrder {
  /// 遭遇回数が多い順（デフォルト）
  encounterCountDesc,

  /// 生物名の五十音・アルファベット順
  nameAsc,

  /// 直近に遭遇した順（最新順）
  recentlyEncountered,
}

/// 生き物図鑑の検索・フィルタリングパラメータ
class MarineLifeFilterParams {
  /// 検索キーワード（生物名または場所名の一部一致）
  final String query;

  /// 出現月フィルター（1〜12。nullの場合は全月）
  final int? month;

  /// 並び替え順序
  final MarineLifeSortOrder sortOrder;

  const MarineLifeFilterParams({
    this.query = '',
    this.month,
    this.sortOrder = MarineLifeSortOrder.encounterCountDesc,
  });
}

/// 生き物図鑑サマリー一覧を取得・フィルタリングするユースケース
///
/// ログブックリポジトリからログ全件を取得し、
/// 生物ごとの遭遇集約サマリーを生成・検索・ソートして返却する。
class GetMarineLifeSummaries
    implements UseCase<List<MarineLifeSummary>, MarineLifeFilterParams> {
  final DiveLogRepository _repository;

  GetMarineLifeSummaries(this._repository);

  @override
  Future<List<MarineLifeSummary>> call(MarineLifeFilterParams params) async {
    final logs = await _repository.getAllLogs();
    var summaries = MarineLifeSummary.fromLogsList(logs);

    // 1. 月フィルター適用
    if (params.month != null) {
      summaries = summaries.where((s) => s.months.contains(params.month!)).toList();
    }

    // 2. 検索キーワード適用（生物名または出現場所の部分一致）
    // ひらがな・カタカナ、大文字小文字を同一視して検索
    final queryTrimmed = params.query.trim().toLowerCase();
    if (queryTrimmed.isNotEmpty) {
      final queryKatakana = _toKatakana(queryTrimmed);
      summaries = summaries.where((s) {
        final nameLower = s.name.toLowerCase();
        final nameKatakana = _toKatakana(nameLower);

        final matchesName = nameLower.contains(queryTrimmed) ||
            nameKatakana.contains(queryKatakana);

        final matchesLocation = s.locations.any((loc) {
          final locLower = loc.toLowerCase();
          final locKatakana = _toKatakana(locLower);
          return locLower.contains(queryTrimmed) ||
              locKatakana.contains(queryKatakana);
        });

        return matchesName || matchesLocation;
      }).toList();
    }

    // 3. ソート適用
    switch (params.sortOrder) {
      case MarineLifeSortOrder.encounterCountDesc:
        summaries.sort((a, b) {
          final cmp = b.encounterCount.compareTo(a.encounterCount);
          if (cmp != 0) return cmp;
          return a.name.compareTo(b.name);
        });
        break;
      case MarineLifeSortOrder.nameAsc:
        summaries.sort((a, b) => a.name.compareTo(b.name));
        break;
      case MarineLifeSortOrder.recentlyEncountered:
        summaries.sort((a, b) {
          final aDate = a.lastEncounterDate ?? DateTime(1970);
          final bDate = b.lastEncounterDate ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
    }

    return summaries;
  }

  /// ひらがなをカタカナに変換する（検索時の表記ゆれ吸収用）
  static String _toKatakana(String text) {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // ひらがな領域 (\u3041: ぁ 〜 \u3096: ゖ) をカタカナ領域へ変換 (+0x60)
      if (code >= 0x3041 && code <= 0x3096) {
        buffer.writeCharCode(code + 0x60);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }
}
