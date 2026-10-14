import '../domain/services/image_picker_service.dart';

/// テスト用の FakeImagePickerService
class FakeImagePickerService implements ImagePickerService {
  List<int>? nextImageBytes;

  FakeImagePickerService({this.nextImageBytes});

  @override
  Future<List<int>?> pickImage({
    required AppImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return nextImageBytes;
  }
}
