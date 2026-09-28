import '../../../core/usecase/usecase.dart';
import '../domain/repositories/gear_repository.dart';

/// 指定された機材のオーバーホール後ダイブ本数をインクリメントするユースケース
class IncrementGearDives implements UseCase<void, List<String>> {
  final GearRepository repository;

  IncrementGearDives(this.repository);

  @override
  Future<void> call(List<String> gearIds) async {
    if (gearIds.isEmpty) return;

    // 重複IDを除去
    final uniqueIds = gearIds.toSet().toList();

    for (final id in uniqueIds) {
      final gear = await repository.getGearById(id);
      if (gear != null) {
        final updated = gear.incrementDives(1);
        await repository.saveGear(updated);
      }
    }
  }
}
