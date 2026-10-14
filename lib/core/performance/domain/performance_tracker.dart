/// パフォーマンストレースの操作ハンドル
abstract class TraceHandle {
  /// トレースに属性（キー・バリュー）を付与
  void putAttribute(String name, String value);

  /// トレースのメトリック値を設定
  void setMetric(String name, int value);

  /// トレースのメトリック値を加算
  void incrementMetric(String name, int by);

  /// トレース計測を終了
  Future<void> stop();
}

/// パフォーマンスモニタリングの抽象インターフェース (Pure Dart)
abstract class PerformanceTracker {
  /// パフォーマンス監視の初期化
  Future<void> initialize();

  /// パフォーマンス収集の有効/無効切り替え
  Future<void> setEnabled(bool enabled);

  /// 名前付きトレースを開始し、手動操作用ハンドルを返却
  TraceHandle startTrace(String name);

  /// 指定した非同期処理ブロックの実行時間を計測・トレース
  Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  });
}
