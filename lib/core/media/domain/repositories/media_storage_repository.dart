/// メディアストレージ（画像・ファイルの保存・削除）のドメイン抽象リポジトリ (Pure Dart)
abstract class MediaStorageRepository {
  /// バイト配列を指定パスにアップロードし、ダウンロードURLを返却する
  Future<String> uploadBytes({
    required String path,
    required List<int> bytes,
    required String contentType,
  });

  /// 指定されたパスまたはダウンロードURLのファイルを削除する
  Future<void> deleteFile(String pathOrUrl);

  /// 指定されたプレフィックス（ディレクトリ・フォルダ）配下の全ファイルを削除する
  Future<void> deleteDirectory(String path);
}
