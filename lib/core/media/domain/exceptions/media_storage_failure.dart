import '../../../error/failures.dart';

/// メディアストレージ操作時のドメイン失敗・エラー
class MediaStorageFailure extends Failure {
  const MediaStorageFailure(super.message);

  factory MediaStorageFailure.uploadFailed([String? details]) =>
      MediaStorageFailure(details ?? '画像のアップロードに失敗しました。通信環境をご確認ください。');

  factory MediaStorageFailure.deleteFailed([String? details]) =>
      MediaStorageFailure(details ?? '画像の削除に失敗しました。');

  factory MediaStorageFailure.fileTooLarge() =>
      const MediaStorageFailure('ファイルサイズが上限（10MB）を超えています。');

  factory MediaStorageFailure.invalidFileType() =>
      const MediaStorageFailure('指定されたファイル形式は対応していません。画像ファイルを選択してください。');
}
