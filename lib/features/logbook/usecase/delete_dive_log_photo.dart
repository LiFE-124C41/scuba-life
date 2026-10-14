import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../../core/usecase/usecase.dart';

class DeleteDiveLogPhotoParams {
  final String photoUrl;

  const DeleteDiveLogPhotoParams({
    required this.photoUrl,
  });
}

/// ダイブログの写真（水中写真等）を Cloud Storage から削除するユースケース (Pure Dart)
class DeleteDiveLogPhoto implements UseCase<void, DeleteDiveLogPhotoParams> {
  final MediaStorageRepository mediaStorageRepository;

  DeleteDiveLogPhoto(this.mediaStorageRepository);

  @override
  Future<void> call(DeleteDiveLogPhotoParams params) async {
    if (params.photoUrl.isNotEmpty) {
      try {
        await mediaStorageRepository.deleteFile(params.photoUrl);
      } catch (_) {}
    }
  }
}
