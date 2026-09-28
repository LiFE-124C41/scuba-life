import '../entities/gear_sale_item.dart';

abstract class GearSaleRepository {
  Future<List<GearSaleItem>> getActiveSaleItems();
}
