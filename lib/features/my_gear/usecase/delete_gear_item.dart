import '../../../core/usecase/usecase.dart';
import '../domain/repositories/gear_repository.dart';

/// 機材削除ユースケース
class DeleteGearItem implements UseCase<void, String> {
  final GearRepository repository;

  DeleteGearItem(this.repository);

  @override
  Future<void> call(String gearId) async {
    await repository.deleteGear(gearId);
  }
}
