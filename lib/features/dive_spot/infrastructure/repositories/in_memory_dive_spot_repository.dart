import '../../domain/entities/dive_spot.dart';
import '../../domain/repositories/dive_spot_repository.dart';

/// メモリ内でダイビングポイント情報を保持するリポジトリ実装
class InMemoryDiveSpotRepository implements DiveSpotRepository {
  final List<DiveSpot> _spots = [
    DiveSpot(
      id: 'spot-osezaki-1',
      name: '大瀬崎 湾内',
      area: '静岡県・西伊豆',
      latitude: 35.0308,
      longitude: 138.7903,
      description: '初心者から上級者まで潜れる穏やかな湾内。水中神社や多種多様なマクロ生物が名物。',
      isFavorite: true,
    ),
    DiveSpot(
      id: 'spot-iop-1',
      name: '伊豆海洋公園 (IOP)',
      area: '静岡県・東伊豆',
      latitude: 34.8906,
      longitude: 139.1361,
      description: '日本屈指のダイビング施設。水中ポストやダイナミックなドロップオフ、季節来遊魚が豊富。',
      isFavorite: true,
    ),
    DiveSpot(
      id: 'spot-kumomi-1',
      name: '雲見 牛着岩',
      area: '静岡県・西伊豆',
      latitude: 34.7212,
      longitude: 138.7425,
      description: '複雑に入り組んだ水中洞窟やアーチが魅力の地形派人気スポット。',
      isFavorite: false,
    ),
    DiveSpot(
      id: 'spot-kushimoto-1',
      name: '串本 備前',
      area: '和歌山県・南紀串本',
      latitude: 33.4735,
      longitude: 135.7725,
      description: '本州最南端の暖流洗う海。広大なサンゴ群落と熱帯魚・ウミガメとの遭遇率が高い。',
      isFavorite: false,
    ),
    DiveSpot(
      id: 'spot-shirahama-1',
      name: '白浜 沈船',
      area: '和歌山県・南紀白浜',
      latitude: 33.6853,
      longitude: 135.3400,
      description: '巨大な沈没船が魚礁となったアドベンチャー感あふれるレックダイビングスポット。',
      isFavorite: false,
    ),
    DiveSpot(
      id: 'spot-kashiwajima-1',
      name: '柏島 後浜',
      area: '高知県・大月町',
      latitude: 32.7711,
      longitude: 132.6322,
      description: '日本トップクラスの生物種数を誇るマクロの聖地。透明度も抜群。',
      isFavorite: false,
    ),
    DiveSpot(
      id: 'spot-kerama-1',
      name: '慶良間諸島・北浜(ニシバマ)',
      area: '沖縄県・座間味/阿嘉島',
      latitude: 26.2083,
      longitude: 127.2889,
      description: '「ケラマブルー」と称される世界屈指の透明度。白い砂地と美しいサンゴ、ウミガメ。',
      isFavorite: true,
    ),
    DiveSpot(
      id: 'spot-miyakojima-1',
      name: '下地島 通り池',
      area: '沖縄県・宮古島',
      latitude: 24.8219,
      longitude: 125.1378,
      description: '外海と海底トンネルで繋がる天然記念物の池。サーモクラインによる幻想的な水色変化が絶景。',
      isFavorite: true,
    ),
    DiveSpot(
      id: 'spot-ishigaki-1',
      name: '川平石崎マンタスクランブル',
      area: '沖縄県・石垣島',
      latitude: 24.4608,
      longitude: 124.1350,
      description: 'マンタのクリーニングステーションとして世界的に有名なポイント。高確率でマンタがホバリング。',
      isFavorite: true,
    ),
  ];

  @override
  Future<List<DiveSpot>> getSpots() async {
    return List.unmodifiable(_spots);
  }

  @override
  Future<DiveSpot?> getSpotById(String id) async {
    try {
      return _spots.firstWhere((spot) => spot.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addSpot(DiveSpot spot) async {
    _spots.removeWhere((s) => s.id == spot.id);
    _spots.add(spot);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final index = _spots.indexWhere((s) => s.id == id);
    if (index != -1) {
      final target = _spots[index];
      _spots[index] = target.copyWith(isFavorite: !target.isFavorite);
    }
  }
}
