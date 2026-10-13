/// 画像ソース (カメラまたはギャラリー)
enum AppImageSource {
  camera,
  gallery,
}

/// 画像選択・取得サービスの抽象インターフェース (Pure Dart)
abstract class ImagePickerService {
  /// カメラまたはギャラリーから画像を選択し、バイト配列を返却する
  /// キャンセルされた場合は null を返却する
  Future<List<int>?> pickImage({
    required AppImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  });
}
