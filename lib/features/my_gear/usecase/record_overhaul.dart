import '../../../core/usecase/usecase.dart';
import '../domain/entities/gear_item.dart';
import '../domain/repositories/gear_repository.dart';

class RecordOverhaulParams {
  final String gearId;
  final DateTime overhaulDate;
  final String? memo;

  const RecordOverhaulParams({
    required this.gearId,
    required this.overhaulDate,
    this.memo,
  });
}

/// オーバーホール実施記録ユースケース
class RecordOverhaul implements UseCase<GearItem, RecordOverhaulParams> {
  final GearRepository repository;

  RecordOverhaul(this.repository);

  @override
  Future<GearItem> call(RecordOverhaulParams params) async {
    final gear = await repository.getGearById(params.gearId);
    if (gear == null) {
      throw StateError('指定された機材が見つかりません: ${params.gearId}');
    }

    final updatedGear = gear.recordOverhaul(
      overhaulDate: params.overhaulDate,
      additionalMemo: params.memo,
    );

    await repository.saveGear(updatedGear);
    return updatedGear;
  }
}
