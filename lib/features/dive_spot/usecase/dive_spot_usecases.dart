import '../../../core/remote_config/domain/repositories/remote_config_repository.dart';
import '../domain/entities/dive_spot.dart';
import '../domain/repositories/dive_spot_repository.dart';

/// 全ダイビングポイント一覧を取得するユースケース
///
/// 既存のスポットリポジトリと Remote Config から取得した動的スポットをマージして返却します。
class GetDiveSpotsUseCase {
  final DiveSpotRepository _repository;
  final RemoteConfigRepository? _remoteConfigRepository;

  GetDiveSpotsUseCase(this._repository, [this._remoteConfigRepository]);

  Future<List<DiveSpot>> execute() async {
    final baseSpots = await _repository.getSpots();
    if (_remoteConfigRepository == null) {
      return baseSpots;
    }

    try {
      final config = _remoteConfigRepository.getCurrentConfig();
      if (config.dynamicDiveSpots.isEmpty) {
        return baseSpots;
      }
      return mergeSpots(baseSpots, config.dynamicDiveSpots);
    } catch (_) {
      return baseSpots;
    }
  }

  /// ベースのスポット一覧と動的スポット一覧をIDベースでマージ
  ///
  /// - 既存IDと重複する場合: 動的スポットの情報（名前、説明、緯度経度等）で更新しつつ、
  ///   ユーザーが付けたお気に入り設定（isFavorite）は維持する
  /// - 新規IDの場合: そのままリストに追加する
  static List<DiveSpot> mergeSpots(
    List<DiveSpot> baseSpots,
    List<DiveSpot> dynamicSpots,
  ) {
    final spotMap = <String, DiveSpot>{};
    for (final spot in baseSpots) {
      spotMap[spot.id] = spot;
    }

    for (final dynamicSpot in dynamicSpots) {
      final existing = spotMap[dynamicSpot.id];
      if (existing != null) {
        spotMap[dynamicSpot.id] = dynamicSpot.copyWith(
          isFavorite: existing.isFavorite,
        );
      } else {
        spotMap[dynamicSpot.id] = dynamicSpot;
      }
    }

    return spotMap.values.toList();
  }
}

/// ダイビングポイントを追加するユースケース
class AddDiveSpotUseCase {
  final DiveSpotRepository _repository;

  AddDiveSpotUseCase(this._repository);

  Future<void> execute(DiveSpot spot) {
    return _repository.addSpot(spot);
  }
}

/// ダイビングポイントのお気に入り状態を切り替えるユースケース
class ToggleFavoriteSpotUseCase {
  final DiveSpotRepository _repository;

  ToggleFavoriteSpotUseCase(this._repository);

  Future<void> execute(String id) {
    return _repository.toggleFavorite(id);
  }
}
