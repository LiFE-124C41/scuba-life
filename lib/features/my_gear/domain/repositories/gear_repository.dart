import '../entities/gear_item.dart';

/// 機材管理リポジトリインターフェース
abstract class GearRepository {
  /// 全ての機材一覧を取得
  Future<List<GearItem>> getAllGear();

  /// IDで機材を取得
  Future<GearItem?> getGearById(String id);

  /// 機材を新規追加または更新
  Future<void> saveGear(GearItem gear);

  /// 機材を削除
  Future<void> deleteGear(String id);
}
