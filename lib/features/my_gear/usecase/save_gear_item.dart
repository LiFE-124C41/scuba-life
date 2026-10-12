import '../../../core/usecase/usecase.dart';
import '../domain/entities/gear_item.dart';
import '../domain/repositories/gear_repository.dart';

/// 機材保存（新規登録または更新）ユースケース
class SaveGearItem implements UseCase<void, GearItem> {
  final GearRepository repository;

  SaveGearItem(this.repository);

  @override
  Future<void> call(GearItem params) async {
    await repository.saveGear(params);
  }
}
