/// アプリケーション内で発生するドメインエラー・失敗の基底クラス
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
