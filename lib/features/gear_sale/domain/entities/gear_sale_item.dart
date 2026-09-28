/// ダイビング器材セール情報エンティティ
class GearSaleItem {
  final String id;
  final String title;
  final String category; // レギュレーター, ダイブコンピューター, BCD, ウェットスーツ等
  final String brand;
  final int originalPrice;
  final int salePrice;
  final String shopName;
  final String itemUrl;
  final DateTime saleEndDate;

  const GearSaleItem({
    required this.id,
    required this.title,
    required this.category,
    required this.brand,
    required this.originalPrice,
    required this.salePrice,
    required this.shopName,
    required this.itemUrl,
    required this.saleEndDate,
  });

  /// 割引率 (%)
  int get discountPercentage {
    if (originalPrice <= 0) return 0;
    return (((originalPrice - salePrice) / originalPrice) * 100).round();
  }
}
