import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dive_spot.dart';
import '../../domain/repositories/dive_spot_repository.dart';

/// Cloud Firestore (`/dive_spots` & `/users/{userId}/favorite_spots`) を利用した DiveSpotRepository の具象実装
class FirestoreDiveSpotRepository implements DiveSpotRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  /// 初期プリセットスポット一覧
  static final List<DiveSpot> defaultPresetSpots = [
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

  FirestoreDiveSpotRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _spotsCollection =>
      _firestore.collection('dive_spots');

  CollectionReference<Map<String, dynamic>> get _favoriteCollection =>
      _firestore.collection('users').doc(userId).collection('favorite_spots');

  @override
  Future<List<DiveSpot>> getSpots() async {
    // 共通マスタとお気に入りを並行取得
    final spotsFuture = _spotsCollection.get();
    final favFuture = _favoriteCollection.get();

    final results = await Future.wait([spotsFuture, favFuture]);
    final spotsSnapshot = results[0];
    final favSnapshot = results[1];

    final favoriteIds = favSnapshot.docs.map((d) => d.id).toSet();

    // 共通マスタが空の場合はプリセットスポットを投入
    if (spotsSnapshot.docs.isEmpty) {
      await _seedPresetSpots();
      return defaultPresetSpots.map((spot) {
        return spot.copyWith(isFavorite: favoriteIds.contains(spot.id) || spot.isFavorite);
      }).toList();
    }

    return spotsSnapshot.docs.map((doc) {
      final isFav = favoriteIds.contains(doc.id);
      return _fromFirestore(doc.data(), doc.id, isFavorite: isFav);
    }).toList();
  }

  @override
  Future<DiveSpot?> getSpotById(String id) async {
    final docSnapshot = await _spotsCollection.doc(id).get();
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      // プリセット内を検索
      try {
        final preset = defaultPresetSpots.firstWhere((s) => s.id == id);
        final favDoc = await _favoriteCollection.doc(id).get();
        return preset.copyWith(isFavorite: favDoc.exists);
      } catch (_) {
        return null;
      }
    }
    final favDoc = await _favoriteCollection.doc(id).get();
    return _fromFirestore(docSnapshot.data()!, docSnapshot.id, isFavorite: favDoc.exists);
  }

  @override
  Future<void> addSpot(DiveSpot spot) async {
    final data = _toFirestore(spot);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['createdBy'] = userId;

    await _spotsCollection.doc(spot.id).set(data);

    if (spot.isFavorite) {
      await _favoriteCollection.doc(spot.id).set({'isFavorite': true});
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final favDoc = await _favoriteCollection.doc(id).get();
    if (favDoc.exists) {
      await _favoriteCollection.doc(id).delete();
    } else {
      await _favoriteCollection.doc(id).set({'isFavorite': true});
    }
  }

  Future<void> _seedPresetSpots() async {
    final batch = _firestore.batch();
    for (final spot in defaultPresetSpots) {
      final docRef = _spotsCollection.doc(spot.id);
      final data = _toFirestore(spot);
      data['isPreset'] = true;
      batch.set(docRef, data);
    }
    await batch.commit();
  }

  DiveSpot _fromFirestore(Map<String, dynamic> data, String id, {required bool isFavorite}) {
    return DiveSpot(
      id: id,
      name: data['name'] as String? ?? 'ダイビングポイント',
      area: data['area'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String? ?? '',
      isFavorite: isFavorite,
    );
  }

  Map<String, dynamic> _toFirestore(DiveSpot spot) {
    return {
      'id': spot.id,
      'name': spot.name,
      'area': spot.area,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'description': spot.description,
    };
  }
}
