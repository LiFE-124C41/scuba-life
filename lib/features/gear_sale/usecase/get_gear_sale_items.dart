import '../../../core/usecase/usecase.dart';
import '../domain/entities/gear_sale_item.dart';
import '../domain/repositories/gear_sale_repository.dart';

class GetGearSaleItems implements UseCase<List<GearSaleItem>, NoParams> {
  final GearSaleRepository _repository;

  GetGearSaleItems(this._repository);

  @override
  Future<List<GearSaleItem>> call(NoParams params) async {
    final items = await _repository.getActiveSaleItems();
    // 割引率の高い順にソート
    items.sort((a, b) => b.discountPercentage.compareTo(a.discountPercentage));
    return items;
  }
}
