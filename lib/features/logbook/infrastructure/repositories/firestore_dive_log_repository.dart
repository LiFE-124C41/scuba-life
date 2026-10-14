import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';

/// Cloud Firestore (`/users/{userId}/dive_logs`) を利用した DiveLogRepository の具象実装
class FirestoreDiveLogRepository implements DiveLogRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final MediaStorageRepository? mediaStorageRepository;

  FirestoreDiveLogRepository({
    required this.userId,
    FirebaseFirestore? firestore,
    this.mediaStorageRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _logsCollection =>
      _firestore.collection('users').doc(userId).collection('dive_logs');

  @override
  Future<List<DiveLog>> getAllLogs() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    try {
      querySnapshot = await _logsCollection
          .orderBy('entryTime', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから即座に取得
      querySnapshot = await _logsCollection
          .orderBy('entryTime', descending: true)
          .get(const GetOptions(source: Source.cache));
    }

    return querySnapshot.docs.map((doc) => _fromFirestore(doc.data(), doc.id)).toList();
  }

  @override
  Future<DiveLog?> getLogById(String id) async {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot;
    try {
      docSnapshot = await _logsCollection.doc(id).get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから取得
      docSnapshot = await _logsCollection.doc(id).get(const GetOptions(source: Source.cache));
    }
    if (!docSnapshot.exists || docSnapshot.data() == null) {
      return null;
    }
    return _fromFirestore(docSnapshot.data()!, docSnapshot.id);
  }

  @override
  Future<void> saveLog(DiveLog log) async {
    final data = _toFirestore(log);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _logsCollection.doc(log.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteLog(String id) async {
    // ログに紐づく Storage 画像ディレクトリを一括削除
    if (mediaStorageRepository != null) {
      try {
        await mediaStorageRepository!.deleteDirectory('users/$userId/dive_logs/$id');
      } catch (_) {}
    }
    await _logsCollection.doc(id).delete();
  }

  /// Firestore ドキュメントデータから DiveLog エンティティへ変換
  DiveLog _fromFirestore(Map<String, dynamic> data, String id) {
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

    final entryTime = parseDate(data['entryTime'], DateTime.now());
    final exitTime = parseDate(data['exitTime'], entryTime.add(const Duration(minutes: 40)));

    return DiveLog(
      id: id,
      scheduleId: data['scheduleId'] as String?,
      date: parseNullableDate(data['date']) ?? DateTime(entryTime.year, entryTime.month, entryTime.day),
      entryTime: entryTime,
      exitTime: exitTime,
      location: data['location'] as String? ?? 'ダイビングポイント',
      spotId: data['spotId'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      diveCenter: data['diveCenter'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 3,
      divePurpose: data['divePurpose'] as String? ?? 'ファンダイビング',
      entryMethod: data['entryMethod'] as String? ?? 'ボート',
      waterArea: data['waterArea'] as String? ?? '海洋',
      waterType: data['waterType'] as String? ?? '海水',
      maxDepthMeter: (data['maxDepthMeter'] as num?)?.toDouble() ?? 0.0,
      avgDepthMeter: (data['avgDepthMeter'] as num?)?.toDouble() ?? 0.0,
      startPressureBar: (data['startPressureBar'] as num?)?.toDouble() ?? 200.0,
      endPressureBar: (data['endPressureBar'] as num?)?.toDouble() ?? 50.0,
      tankVolumeLiter: (data['tankVolumeLiter'] as num?)?.toDouble() ?? 10.0,
      cylinderMaterial: data['cylinderMaterial'] as String? ?? 'スチール',
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      plannedDepthMeter: (data['plannedDepthMeter'] as num?)?.toDouble(),
      plannedDurationMinutes: (data['plannedDurationMinutes'] as num?)?.toInt(),
      plannedReservePressureBar: (data['plannedReservePressureBar'] as num?)?.toDouble(),
      weather: data['weather'] as String? ?? '晴れ',
      airTemp: (data['airTemp'] as num?)?.toDouble(),
      waterTempMin: (data['waterTempMin'] as num?)?.toDouble(),
      waterTempMax: (data['waterTempMax'] as num?)?.toDouble(),
      visibilityMeter: (data['visibilityMeter'] as num?)?.toDouble(),
      underwaterCurrent: data['underwaterCurrent'] as String? ?? 'なし',
      surfaceCurrent: data['surfaceCurrent'] as String? ?? '穏やか',
      tideType: data['tideType'] as String? ?? '中潮',
      highTideTime1: data['highTideTime1'] as String?,
      lowTideTime1: data['lowTideTime1'] as String?,
      highTideTime2: data['highTideTime2'] as String?,
      lowTideTime2: data['lowTideTime2'] as String?,
      buddies: (data['buddies'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      marineLife: (data['marineLife'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      selectedGearIds: (data['selectedGearIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      equipment: data['equipment'] as String? ?? '',
      notes: data['notes'] as String? ?? '',
      photoUrls: (data['photoUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// DiveLog エンティティから Firestore 保存用 Map へ変換
  Map<String, dynamic> _toFirestore(DiveLog log) {
    return {
      'id': log.id,
      if (log.scheduleId != null) 'scheduleId': log.scheduleId,
      'date': Timestamp.fromDate(log.date),
      'entryTime': Timestamp.fromDate(log.entryTime),
      'exitTime': Timestamp.fromDate(log.exitTime),
      'location': log.location,
      if (log.spotId != null) 'spotId': log.spotId,
      if (log.latitude != null) 'latitude': log.latitude,
      if (log.longitude != null) 'longitude': log.longitude,
      'diveCenter': log.diveCenter,
      'rating': log.rating,
      'divePurpose': log.divePurpose,
      'entryMethod': log.entryMethod,
      'waterArea': log.waterArea,
      'waterType': log.waterType,
      'maxDepthMeter': log.maxDepthMeter,
      'avgDepthMeter': log.avgDepthMeter,
      'startPressureBar': log.startPressureBar,
      'endPressureBar': log.endPressureBar,
      'tankVolumeLiter': log.tankVolumeLiter,
      'cylinderMaterial': log.cylinderMaterial,
      if (log.weightKg != null) 'weightKg': log.weightKg,
      if (log.plannedDepthMeter != null) 'plannedDepthMeter': log.plannedDepthMeter,
      if (log.plannedDurationMinutes != null) 'plannedDurationMinutes': log.plannedDurationMinutes,
      if (log.plannedReservePressureBar != null) 'plannedReservePressureBar': log.plannedReservePressureBar,
      'weather': log.weather,
      if (log.airTemp != null) 'airTemp': log.airTemp,
      if (log.waterTempMin != null) 'waterTempMin': log.waterTempMin,
      if (log.waterTempMax != null) 'waterTempMax': log.waterTempMax,
      if (log.visibilityMeter != null) 'visibilityMeter': log.visibilityMeter,
      'underwaterCurrent': log.underwaterCurrent,
      'surfaceCurrent': log.surfaceCurrent,
      'tideType': log.tideType,
      if (log.highTideTime1 != null) 'highTideTime1': log.highTideTime1,
      if (log.lowTideTime1 != null) 'lowTideTime1': log.lowTideTime1,
      if (log.highTideTime2 != null) 'highTideTime2': log.highTideTime2,
      if (log.lowTideTime2 != null) 'lowTideTime2': log.lowTideTime2,
      'buddies': log.buddies,
      'marineLife': log.marineLife,
      'selectedGearIds': log.selectedGearIds,
      'equipment': log.equipment,
      'notes': log.notes,
      'photoUrls': log.photoUrls,
    };
  }
}
