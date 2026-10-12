import '../entities/dive_spot.dart';

/// ダイビングポイントリポジトリのインターフェース
abstract class DiveSpotRepository {
  /// 全ダイビングポイント一覧を取得
  Future<List<DiveSpot>> getSpots();

  /// IDで特定のダイビングポイントを取得
  Future<DiveSpot?> getSpotById(String id);

  /// 新しいダイビングポイントを追加
  Future<void> addSpot(DiveSpot spot);

  /// お気に入り状態をトグル切り替え
  Future<void> toggleFavorite(String id);
}
