import '../../../core/usecase/usecase.dart';
import '../domain/entities/gear_item.dart';
import '../domain/repositories/gear_repository.dart';

/// 機材一覧取得ユースケース
class GetGearItems implements UseCase<List<GearItem>, NoParams> {
  final GearRepository repository;

  GetGearItems(this.repository);

  @override
  Future<List<GearItem>> call(NoParams params) async {
    final items = await repository.getAllGear();
    // オーバーホール緊急度（要OH -> まもなく -> 良好 -> 対象外）順にソートして返却
    final sorted = List<GearItem>.from(items);
    sorted.sort((a, b) {
      final statusA = a.calculateStatus();
      final statusB = b.calculateStatus();
      
      final priorityA = _statusPriority(statusA);
      final priorityB = _statusPriority(statusB);

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // 同一ステータス内は残り日数が少ない順
      final daysA = a.calculateDaysUntilOverhaul();
      final daysB = b.calculateDaysUntilOverhaul();
      return daysA.compareTo(daysB);
    });
    return sorted;
  }

  int _statusPriority(OverhaulStatus status) {
    switch (status) {
      case OverhaulStatus.overdue:
        return 0; // 最優先で警告
      case OverhaulStatus.warning:
        return 1;
      case OverhaulStatus.good:
        return 2;
      case OverhaulStatus.none:
        return 3;
    }
  }
}
