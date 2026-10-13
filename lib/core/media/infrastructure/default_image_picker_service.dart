import 'package:image_picker/image_picker.dart';
import '../domain/services/image_picker_service.dart';

/// image_picker パッケージを用いた本番用 ImagePickerService 実装
class DefaultImagePickerService implements ImagePickerService {
  final ImagePicker _picker;

  DefaultImagePickerService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<List<int>?> pickImage({
    required AppImageSource source,
    double? maxWidth = 1920,
    double? maxHeight = 1920,
    int? imageQuality = 85,
  }) async {
    final pickerSource = source == AppImageSource.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    final xFile = await _picker.pickImage(
      source: pickerSource,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    if (xFile == null) return null;
    return await xFile.readAsBytes();
  }
}
