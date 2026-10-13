/// ダイビング指導団体および認定ランクの定数・選択肢定義 (Pure Dart)
class DiverCertification {
  const DiverCertification._();

  /// 代表的なダイビング指導団体 (C-Card Issuing Organizations)
  static const List<String> organizations = [
    'PADI',
    'NAUI',
    'SSI',
    'BSAC',
    'CMAS',
    'SNSI',
    'STARS',
    'その他',
  ];

  /// 代表的なダイバー認定ランク (Certification Levels)
  static const List<String> levels = [
    'OW (オープン・ウォーター)',
    'AOW (アドヴァンスド)',
    'RED (レスキュー・ダイバー)',
    'MSD (マスター・スクーバ・ダイバー)',
    'DM (ダイブマスター)',
    'AI (アシスタント・インストラクター)',
    'OWSI (インストラクター)',
    'その他',
  ];
}
