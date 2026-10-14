import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../../core/usecase/usecase.dart';

class UploadDiveLogPhotoParams {
  final String userId;
  final String logId;
  final List<int> imageBytes;
  final String contentType;
  final String? customPhotoId;

  const UploadDiveLogPhotoParams({
    required this.userId,
    required this.logId,
    required this.imageBytes,
    this.contentType = 'image/webp',
    this.customPhotoId,
  });
}

/// ダイブログの写真（水中写真等）を Cloud Storage にアップロードし、URLを返すユースケース (Pure Dart)
class UploadDiveLogPhoto implements UseCase<String, UploadDiveLogPhotoParams> {
  final MediaStorageRepository mediaStorageRepository;

  UploadDiveLogPhoto(this.mediaStorageRepository);

  @override
  Future<String> call(UploadDiveLogPhotoParams params) async {
    final photoId = params.customPhotoId ??
        'photo_${DateTime.now().millisecondsSinceEpoch}_${params.imageBytes.length}';
    final detectedContentType = _detectContentType(params.imageBytes, params.contentType);
    final path = 'users/${params.userId}/dive_logs/${params.logId}/$photoId.webp';

    final downloadUrl = await mediaStorageRepository.uploadBytes(
      path: path,
      bytes: params.imageBytes,
      contentType: detectedContentType,
    );

    return downloadUrl;
  }

  String _detectContentType(List<int> bytes, String fallback) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return fallback;
  }
}
