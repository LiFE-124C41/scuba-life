import '../domain/exceptions/media_storage_failure.dart';
import '../domain/repositories/media_storage_repository.dart';

/// テストおよびオフライン・開発用のインメモリ MediaStorageRepository 実装
class InMemoryMediaStorageRepository implements MediaStorageRepository {
  final Map<String, List<int>> storedFiles = {};
  bool shouldFailOnUpload = false;
  bool shouldFailOnDelete = false;

  @override
  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    required String contentType,
  }) async {
    if (shouldFailOnUpload) {
      throw MediaStorageFailure.uploadFailed('Mock upload failure');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw MediaStorageFailure.fileTooLarge();
    }
    if (!contentType.startsWith('image/')) {
      throw MediaStorageFailure.invalidFileType();
    }

    storedFiles[path] = List.from(bytes);
    return 'https://mockstorage.example.com/$path';
  }

  @override
  Future<void> deleteFile(String pathOrUrl) async {
    if (shouldFailOnDelete) {
      throw MediaStorageFailure.deleteFailed('Mock delete failure');
    }

    final path = pathOrUrl.replaceFirst('https://mockstorage.example.com/', '');
    storedFiles.remove(path);
  }

  void clear() {
    storedFiles.clear();
    shouldFailOnUpload = false;
    shouldFailOnDelete = false;
  }
}
