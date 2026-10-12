import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/gear_item.dart';
import '../../domain/repositories/gear_repository.dart';

/// Cloud Firestore (`/users/{userId}/gear_items`) を利用した GearRepository の具象実装
class FirestoreGearRepository implements GearRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestoreGearRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _gearCollection =>
      _firestore.collection('users').doc(userId).collection('gear_items');

  @override
  Future<List<GearItem>> getAllGear() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    try {
      querySnapshot = await _gearCollection
          .orderBy('purchaseDate', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから取得
      querySnapshot = await _gearCollection
          .orderBy('purchaseDate', descending: true)
          .get(const GetOptions(source: Source.cache));
    }

    return querySnapshot.docs.map((doc) => _fromFirestore(doc.data(), doc.id)).toList();
  }

  @override
  Future<GearItem?> getGearById(String id) async {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot;
    try {
      docSnapshot = await _gearCollection.doc(id).get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから取得
      docSnapshot = await _gearCollection.doc(id).get(const GetOptions(source: Source.cache));
    }
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return _fromFirestore(docSnapshot.data()!, docSnapshot.id);
  }

  @override
  Future<void> saveGear(GearItem gear) async {
    final data = _toFirestore(gear);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _gearCollection.doc(gear.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteGear(String id) async {
    await _gearCollection.doc(id).delete();
  }

  /// Firestore ドキュメントデータから GearItem エンティティへ変換
  GearItem _fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    GearCategory parseCategory(String? categoryName) {
      if (categoryName == null) return GearCategory.accessories;
      try {
        return GearCategory.values.firstWhere(
          (e) => e.name == categoryName || e.label == categoryName,
        );
      } catch (_) {
        return GearCategory.accessories;
      }
    }

    final purchaseDate = parseDate(data['purchaseDate'], DateTime.now());

    return GearItem(
      id: id,
      name: data['name'] as String? ?? '機材',
      category: parseCategory(data['category'] as String?),
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      serialNumber: data['serialNumber'] as String? ?? '',
      purchaseDate: purchaseDate,
      lastOverhaulDate: parseNullableDate(data['lastOverhaulDate']),
      divesSinceOverhaul: (data['divesSinceOverhaul'] as num?)?.toInt() ?? 0,
      overhaulIntervalMonths: (data['overhaulIntervalMonths'] as num?)?.toInt() ?? 12,
      overhaulIntervalDives: (data['overhaulIntervalDives'] as num?)?.toInt(),
      requiresOverhaul: data['requiresOverhaul'] as bool? ?? false,
      memo: data['memo'] as String? ?? '',
    );
  }

  /// GearItem エンティティから Firestore 保存用 Map へ変換
  Map<String, dynamic> _toFirestore(GearItem gear) {
    return {
      'id': gear.id,
      'name': gear.name,
      'category': gear.category.name,
      'brand': gear.brand,
      'model': gear.model,
      'serialNumber': gear.serialNumber,
      'purchaseDate': Timestamp.fromDate(gear.purchaseDate),
      if (gear.lastOverhaulDate != null)
        'lastOverhaulDate': Timestamp.fromDate(gear.lastOverhaulDate!),
      'divesSinceOverhaul': gear.divesSinceOverhaul,
      'overhaulIntervalMonths': gear.overhaulIntervalMonths,
      if (gear.overhaulIntervalDives != null)
        'overhaulIntervalDives': gear.overhaulIntervalDives,
      'requiresOverhaul': gear.requiresOverhaul,
      'memo': gear.memo,
    };
  }
}
