import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../domain/exceptions/media_storage_failure.dart';
import '../domain/repositories/media_storage_repository.dart';

/// Firebase Cloud Storage を用いた本番用 MediaStorageRepository 実装
class FirebaseMediaStorageRepository implements MediaStorageRepository {
  final FirebaseStorage _storage;

  FirebaseMediaStorageRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    try {
      if (bytes.length > 10 * 1024 * 1024) {
        throw MediaStorageFailure.fileTooLarge();
      }

      final ref = _storage.ref(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        cacheControl: 'public, max-age=31536000', // 1年間キャッシュ
      );

      final uploadTask = ref.putData(Uint8List.fromList(bytes), metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('FirebaseStorage upload error: ${e.code} - ${e.message}');
      throw MediaStorageFailure.uploadFailed(e.message);
    } catch (e) {
      if (e is MediaStorageFailure) rethrow;
      throw MediaStorageFailure.uploadFailed(e.toString());
    }
  }

  @override
  Future<void> deleteFile(String pathOrUrl) async {
    try {
      Reference ref;
      if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
        ref = _storage.refFromURL(pathOrUrl);
      } else {
        ref = _storage.ref(pathOrUrl);
      }
      await ref.delete();
    } on FirebaseException catch (e) {
      debugPrint('FirebaseStorage delete error: ${e.code} - ${e.message}');
      // 既に存在しない場合はエラーとしない (冪等性の担保)
      if (e.code != 'object-not-found') {
        throw MediaStorageFailure.deleteFailed(e.message);
      }
    } catch (e) {
      if (e is MediaStorageFailure) rethrow;
      throw MediaStorageFailure.deleteFailed(e.toString());
    }
  }
}
