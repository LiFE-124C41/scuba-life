import '../../domain/entities/gear_sale_item.dart';
import '../../domain/repositories/gear_sale_repository.dart';

class MockGearSaleRepository implements GearSaleRepository {
  @override
  Future<List<GearSaleItem>> getActiveSaleItems() async {
    return [
      GearSaleItem(
        id: 'sale-001',
        title: 'ソーラー充電式ダイブコンピューター T1',
        category: 'ダイブコンピューター',
        brand: 'AquaTech',
        originalPrice: 98000,
        salePrice: 68600,
        shopName: 'ダイバーズオンライン',
        itemUrl: 'https://example.com/items/001',
        saleEndDate: DateTime.now().add(const Duration(days: 5)),
      ),
      GearSaleItem(
        id: 'sale-002',
        title: '超軽量チタンレギュレーター セット',
        category: 'レギュレーター',
        brand: 'OceanMaster',
        originalPrice: 154000,
        salePrice: 115500,
        shopName: 'マリンプロショップ',
        itemUrl: 'https://example.com/items/002',
        saleEndDate: DateTime.now().add(const Duration(days: 3)),
      ),
      GearSaleItem(
        id: 'sale-003',
        title: '5mmスーパーストレッチ ウェットスーツ',
        category: 'スーツ',
        brand: 'BlueWave',
        originalPrice: 48000,
        salePrice: 28800,
        shopName: 'サマーダイブストア',
        itemUrl: 'https://example.com/items/003',
        saleEndDate: DateTime.now().add(const Duration(days: 10)),
      ),
    ];
  }
}
