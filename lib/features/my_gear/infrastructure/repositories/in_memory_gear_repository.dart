import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/gear_repository.dart';

/// インメモリ機材リポジトリ実装
class InMemoryGearRepository implements GearRepository {
  final List<GearItem> _items = [];

  InMemoryGearRepository({List<GearItem>? initialData}) {
    if (initialData != null) {
      _items.addAll(initialData);
    } else {
      _initializePresets();
    }
  }

  void _initializePresets() {
    final now = DateTime.now();
    _items.addAll([
      GearItem(
        id: 'gear-1',
        name: 'Apeks XTX200 レギュレーターセット',
        category: GearCategory.regulator,
        brand: 'Apeks',
        model: 'XTX200 + オクトパスXTX40 + 2連ゲージ',
        serialNumber: 'APX-2023-8831',
        purchaseDate: now.subtract(const Duration(days: 700)),
        lastOverhaulDate: now.subtract(const Duration(days: 345)), // 約11.5ヶ月前（まもなく1年）
        divesSinceOverhaul: 82,
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        memo: '前回OH: 〇〇ダイブサービス（1st/2ndステージキット交換済み）。次回は高圧ホース点検。',
      ),
      GearItem(
        id: 'gear-2',
        name: 'SCUBAPRO Hydros Pro BCD',
        category: GearCategory.bcd,
        brand: 'SCUBAPRO',
        model: 'HYDROS PRO Mサイズ',
        serialNumber: 'SP-HYD-55012',
        purchaseDate: now.subtract(const Duration(days: 800)),
        lastOverhaulDate: now.subtract(const Duration(days: 410)), // 1年1ヶ月以上前（期限切れ）
        divesSinceOverhaul: 108,
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
        memo: 'インフレーターバルブ洗浄および排気弁Oリング交換が必要。早めにショップへ持ち込むこと。',
      ),
      GearItem(
        id: 'gear-3',
        name: 'SUUNTO D5 ダイブコンピューター',
        category: GearCategory.diveComputer,
        brand: 'SUUNTO',
        model: 'D5 All Black',
        serialNumber: 'SN-D5-9921',
        purchaseDate: now.subtract(const Duration(days: 300)),
        lastOverhaulDate: now.subtract(const Duration(days: 120)), // 4ヶ月前（良好）
        divesSinceOverhaul: 25,
        overhaulIntervalMonths: 24, // 2年周期点検
        overhaulIntervalDives: 200,
        memo: 'バッテリー充電良好。最新ファームウェア適用済み。',
      ),
      GearItem(
        id: 'gear-4',
        name: 'GULL マンティスLV & ミューフィン',
        category: GearCategory.maskSnorkelFin,
        brand: 'GULL',
        model: 'Mantis LV (UV420) & MEW Fin Lサイズ',
        serialNumber: '',
        purchaseDate: now.subtract(const Duration(days: 400)),
        requiresOverhaul: false,
        memo: '使用後は真水洗浄・陰干しを徹底。フィンストラップの亀裂に注意。',
      ),
      GearItem(
        id: 'gear-5',
        name: 'World Dive 5mm ウエットスーツ',
        category: GearCategory.suit,
        brand: 'ワールドダイブ',
        model: 'ZMD フルオーダー 5mm',
        serialNumber: 'WD-2024-001',
        purchaseDate: now.subtract(const Duration(days: 200)),
        requiresOverhaul: false,
        memo: '手首・足首ファスナー付き。裏起毛スキン仕様。',
      ),
    ]);
  }

  @override
  Future<List<GearItem>> getAllGear() async {
    return List.from(_items);
  }

  @override
  Future<GearItem?> getGearById(String id) async {
    return _items.where((g) => g.id == id).firstOrNull;
  }

  @override
  Future<void> saveGear(GearItem gear) async {
    final index = _items.indexWhere((g) => g.id == gear.id);
    if (index >= 0) {
      _items[index] = gear;
    } else {
      _items.add(gear);
    }
  }

  @override
  Future<void> deleteGear(String id) async {
    _items.removeWhere((g) => g.id == id);
  }
}
