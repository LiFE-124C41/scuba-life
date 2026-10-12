import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/dive_schedule.dart';
import '../../domain/repositories/dive_schedule_repository.dart';

/// Cloud Firestore (`/users/{userId}/dive_schedules`) を利用した DiveScheduleRepository の具象実装
class FirestoreScheduleRepository implements DiveScheduleRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestoreScheduleRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _schedulesCollection =>
      _firestore.collection('users').doc(userId).collection('dive_schedules');

  @override
  Future<List<DiveSchedule>> getUpcomingSchedules() async {
    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    try {
      querySnapshot = await _schedulesCollection
          .orderBy('eventDate', descending: false)
          .get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから取得
      querySnapshot = await _schedulesCollection
          .orderBy('eventDate', descending: false)
          .get(const GetOptions(source: Source.cache));
    }

    return querySnapshot.docs.map((doc) => _fromFirestore(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> addSchedule(DiveSchedule schedule) async {
    final data = _toFirestore(schedule);
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _schedulesCollection.doc(schedule.id).set(data);
  }

  @override
  Future<void> updateSchedule(DiveSchedule schedule) async {
    final data = _toFirestore(schedule);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _schedulesCollection.doc(schedule.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await _schedulesCollection.doc(id).delete();
  }

  /// Firestore ドキュメントデータから DiveSchedule エンティティへ変換
  DiveSchedule _fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    return DiveSchedule(
      id: id,
      title: data['title'] as String? ?? 'ダイビング予定',
      eventDate: parseDate(data['eventDate'], DateTime.now()),
      destination: data['destination'] as String? ?? '',
      spotId: data['spotId'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      diveShop: data['diveShop'] as String? ?? '',
      plannedDivesCount: (data['plannedDivesCount'] as num?)?.toInt() ?? 2,
      memo: data['memo'] as String? ?? '',
      checkedGearIds: (data['checkedGearIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      targetGearIds: (data['targetGearIds'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }

  /// DiveSchedule エンティティから Firestore 保存用 Map へ変換
  Map<String, dynamic> _toFirestore(DiveSchedule schedule) {
    return {
      'id': schedule.id,
      'title': schedule.title,
      'eventDate': Timestamp.fromDate(schedule.eventDate),
      'destination': schedule.destination,
      if (schedule.spotId != null) 'spotId': schedule.spotId,
      if (schedule.latitude != null) 'latitude': schedule.latitude,
      if (schedule.longitude != null) 'longitude': schedule.longitude,
      'diveShop': schedule.diveShop,
      'plannedDivesCount': schedule.plannedDivesCount,
      'memo': schedule.memo,
      'checkedGearIds': schedule.checkedGearIds,
      if (schedule.targetGearIds != null) 'targetGearIds': schedule.targetGearIds,
    };
  }
}
