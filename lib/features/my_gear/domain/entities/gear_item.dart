/// 機材カテゴリー
enum GearCategory {
  regulator('レギュレーター', true),
  bcd('BCD (浮力調整具)', true),
  diveComputer('ダイブコンピューター', true),
  suit('ウェット/ドライスーツ', false),
  maskSnorkelFin('マスク・スノーケル・フィン', false),
  accessories('その他・水中ライト・アクセサリー', false);

  final String label;
  /// デフォルトで定期オーバーホール・点検が推奨されるか
  final bool defaultRequiresOverhaul;

  const GearCategory(this.label, this.defaultRequiresOverhaul);
}

/// オーバーホールのステータス
enum OverhaulStatus {
  /// オーバーホール期限切れ（要オーバーホール）
  overdue('要オーバーホール', 0xFFD32F2F),
  /// もうすぐオーバーホール推奨時期（30日以内またはダイブ本数接近）
  warning('まもなく推奨時期', 0xFFF57C00),
  /// 良好（期限まで十分な余裕あり）
  good('良好', 0xFF388E3C),
  /// オーバーホール対象外
  none('対象外', 0xFF757575);

  final String label;
  final int colorValue;

  const OverhaulStatus(this.label, this.colorValue);
}

/// 自分のダイビング機材エンティティ
class GearItem {
  final String id;
  final String name;
  final GearCategory category;
  final String brand;
  final String model;
  final String serialNumber;
  final DateTime purchaseDate;
  final DateTime? lastOverhaulDate;
  final int divesSinceOverhaul;
  /// 推奨オーバーホール周期（月数）。通常12ヶ月（1年）
  final int overhaulIntervalMonths;
  /// 推奨オーバーホールダイブ本数（本）。通常50〜100本（nullの場合は本数基準なし）
  final int? overhaulIntervalDives;
  /// 定期オーバーホールを必要とする機材か（レギュレーター、BCD、ダイブコンピューター等）
  final bool requiresOverhaul;
  final String memo;

  GearItem({
    required this.id,
    required this.name,
    required this.category,
    this.brand = '',
    this.model = '',
    this.serialNumber = '',
    required this.purchaseDate,
    this.lastOverhaulDate,
    this.divesSinceOverhaul = 0,
    this.overhaulIntervalMonths = 12,
    this.overhaulIntervalDives = 100,
    bool? requiresOverhaul,
    this.memo = '',
  }) : requiresOverhaul = requiresOverhaul ?? category.defaultRequiresOverhaul {
    if (name.trim().isEmpty) {
      throw ArgumentError('機材名は必須です。');
    }
    if (divesSinceOverhaul < 0) {
      throw ArgumentError('オーバーホール後ダイブ本数は0以上である必要があります。');
    }
    if (overhaulIntervalMonths <= 0) {
      throw ArgumentError('オーバーホール周期(月数)は1以上である必要があります。');
    }
    if (overhaulIntervalDives != null && overhaulIntervalDives! <= 0) {
      throw ArgumentError('オーバーホール周期(ダイブ本数)は1以上である必要があります。');
    }
  }

  /// 基準となる日付（最終OH日。なければ購入日）
  DateTime get baseDate => lastOverhaulDate ?? purchaseDate;

  /// 次回推奨オーバーホール日
  DateTime get nextOverhaulDate {
    return DateTime(
      baseDate.year,
      baseDate.month + overhaulIntervalMonths,
      baseDate.day,
    );
  }

  /// 次回オーバーホールまでの残り日数（現在日時を基準に計算）
  int calculateDaysUntilOverhaul([DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(nextOverhaulDate.year, nextOverhaulDate.month, nextOverhaulDate.day);
    return target.difference(today).inDays;
  }

  /// 次回オーバーホールまでの残りダイブ本数（設定されている場合）
  int? calculateDivesUntilOverhaul() {
    if (overhaulIntervalDives == null) return null;
    return overhaulIntervalDives! - divesSinceOverhaul;
  }

  /// 現在のオーバーホールステータスを判定
  OverhaulStatus calculateStatus([DateTime? currentDate]) {
    if (!requiresOverhaul) {
      return OverhaulStatus.none;
    }

    final daysRemaining = calculateDaysUntilOverhaul(currentDate);
    final divesRemaining = calculateDivesUntilOverhaul();

    // 日数超過、またはダイブ本数超過の場合は期限切れ
    if (daysRemaining <= 0 || (divesRemaining != null && divesRemaining <= 0)) {
      return OverhaulStatus.overdue;
    }

    // 30日以内、または残りダイブ本数10本以下の場合は警告（まもなく）
    if (daysRemaining <= 30 || (divesRemaining != null && divesRemaining <= 10)) {
      return OverhaulStatus.warning;
    }

    return OverhaulStatus.good;
  }

  /// オーバーホール実施を記録して新しいインスタンスを生成
  GearItem recordOverhaul({
    required DateTime overhaulDate,
    String? additionalMemo,
  }) {
    final newMemo = additionalMemo != null && additionalMemo.trim().isNotEmpty
        ? (memo.isEmpty
            ? additionalMemo
            : '$memo\n[OH記録 ${overhaulDate.year}/${overhaulDate.month}/${overhaulDate.day}] $additionalMemo')
        : memo;

    return copyWith(
      lastOverhaulDate: overhaulDate,
      divesSinceOverhaul: 0,
      memo: newMemo,
    );
  }

  /// ダイブ本数をインクリメントして新しいインスタンスを生成
  GearItem incrementDives([int count = 1]) {
    if (count <= 0) return this;
    return copyWith(
      divesSinceOverhaul: divesSinceOverhaul + count,
    );
  }

  /// ダイブ本数をデクリメントして新しいインスタンスを生成（0未満にはならない）
  GearItem decrementDives([int count = 1]) {
    if (count <= 0) return this;
    final newCount = divesSinceOverhaul - count;
    return copyWith(
      divesSinceOverhaul: newCount < 0 ? 0 : newCount,
    );
  }

  GearItem copyWith({
    String? id,
    String? name,
    GearCategory? category,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchaseDate,
    DateTime? lastOverhaulDate,
    int? divesSinceOverhaul,
    int? overhaulIntervalMonths,
    int? overhaulIntervalDives,
    bool? requiresOverhaul,
    String? memo,
  }) {
    return GearItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      lastOverhaulDate: lastOverhaulDate ?? this.lastOverhaulDate,
      divesSinceOverhaul: divesSinceOverhaul ?? this.divesSinceOverhaul,
      overhaulIntervalMonths: overhaulIntervalMonths ?? this.overhaulIntervalMonths,
      overhaulIntervalDives: overhaulIntervalDives ?? this.overhaulIntervalDives,
      requiresOverhaul: requiresOverhaul ?? this.requiresOverhaul,
      memo: memo ?? this.memo,
    );
  }
}
