import '../domain/entities/dive_spot.dart';
import '../domain/repositories/dive_spot_repository.dart';

/// 全ダイビングポイント一覧を取得するユースケース
class GetDiveSpotsUseCase {
  final DiveSpotRepository _repository;

  GetDiveSpotsUseCase(this._repository);

  Future<List<DiveSpot>> execute() {
    return _repository.getSpots();
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
