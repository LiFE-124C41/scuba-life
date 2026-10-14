import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/user_repository.dart';

/// Cloud Firestore (`/users/{userId}`) を利用した UserRepository の具象実装
class FirestoreUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<UserAccount?> watchUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      return _fromFirestore(snapshot.data()!, snapshot.id);
    });
  }

  @override
  Future<UserAccount?> getUserProfile(String userId) async {
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _usersCollection.doc(userId).get(const GetOptions(source: Source.serverAndCache));
    } catch (_) {
      // オフライン・圏外時: ローカルキャッシュから取得
      doc = await _usersCollection.doc(userId).get(const GetOptions(source: Source.cache));
    }
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return _fromFirestore(doc.data()!, doc.id);
  }

  @override
  Future<void> saveUserProfile(UserAccount user) async {
    final data = _toFirestore(user);
    data['updatedAt'] = FieldValue.serverTimestamp();

    await _usersCollection.doc(user.id).set(
          data,
          SetOptions(merge: true),
        );
  }

  @override
  Future<UserAccount> syncInitialProfile(UserAccount user) async {
    final docRef = _usersCollection.doc(user.id);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      // 既存プロファイルを読み込み、Authの最新情報（email等）で必要ならマージ
      final existing = _fromFirestore(doc.data()!, doc.id);
      final merged = existing.copyWith(
        email: user.email.isNotEmpty ? user.email : existing.email,
        displayName: (existing.displayName != null && existing.displayName!.isNotEmpty)
            ? existing.displayName
            : user.displayName,
        photoUrl: existing.photoUrl ?? user.photoUrl,
        isEmailVerified: user.isEmailVerified,
      );

      // マージ情報があれば更新
      if (merged != existing) {
        await docRef.set(_toFirestore(merged), SetOptions(merge: true));
      }
      return merged;
    } else {
      // ドキュメント未作成時は新規登録
      final initialData = _toFirestore(user);
      initialData['createdAt'] = FieldValue.serverTimestamp();
      initialData['updatedAt'] = FieldValue.serverTimestamp();
      await docRef.set(initialData);
      return user;
    }
  }

  @override
  Future<void> deleteUserData(String userId) async {
    final userDocRef = _usersCollection.doc(userId);
    final subcollections = ['dive_logs', 'gear_items', 'dive_schedules', 'favorite_spots'];

    for (final sub in subcollections) {
      try {
        final snapshot = await userDocRef.collection(sub).get();
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (_) {}
    }

    try {
      await userDocRef.delete();
    } catch (_) {}
  }

  /// Firestore ドキュメントデータから UserAccount エンティティへ変換
  UserAccount _fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return UserAccount(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isEmailVerified: data['isEmailVerified'] as bool? ?? false,
      certificationOrg: data['certificationOrg'] as String?,
      certificationLevel: data['certificationLevel'] as String?,
      cCardNumber: data['cCardNumber'] as String?,
      totalDivesOffset: (data['totalDivesOffset'] as num?)?.toInt() ?? 0,
      cCardFrontUrl: data['cCardFrontUrl'] as String?,
      cCardBackUrl: data['cCardBackUrl'] as String?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  /// UserAccount エンティティから Firestore 保存用 Map へ変換
  Map<String, dynamic> _toFirestore(UserAccount user) {
    return {
      'uid': user.id,
      'email': user.email,
      if (user.displayName != null) 'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'isEmailVerified': user.isEmailVerified,
      if (user.certificationOrg != null) 'certificationOrg': user.certificationOrg,
      if (user.certificationLevel != null) 'certificationLevel': user.certificationLevel,
      if (user.cCardNumber != null) 'cCardNumber': user.cCardNumber,
      'totalDivesOffset': user.totalDivesOffset,
      'cCardFrontUrl': user.cCardFrontUrl,
      'cCardBackUrl': user.cCardBackUrl,
      if (user.createdAt != null) 'createdAt': Timestamp.fromDate(user.createdAt!),
    };
  }
}
