/// ユースケースの抽象基底インターフェース
///
/// 外部フレームワークに依存せず、ビジネスロジックの呼び出しインターフェースを統一する
abstract class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

class NoParams {
  const NoParams();
}
