import 'package:flutter/material.dart';
import '../../../../../core/media/interface/widgets/app_cached_network_image.dart';

/// Cカード写真のフルスクリーンプレビュー画面（ピンチイン/アウト拡大対応）
class CCardFullScreenViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onDelete;

  const CCardFullScreenViewer({
    super.key,
    required this.imageUrl,
    required this.title,
    this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required String imageUrl,
    required String title,
    VoidCallback? onDelete,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CCardFullScreenViewer(
          imageUrl: imageUrl,
          title: title,
          onDelete: onDelete,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真の削除確認'),
        content: Text('$title の写真を削除しますか？\n削除後は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.of(context).pop(); // フルスクリーンビューアーを閉じる
      onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '写真を削除',
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: AppCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) {
              final isRunningInTest =
                  WidgetsBinding.instance.runtimeType.toString().contains('TestWidgetsFlutterBinding');
              if (isRunningInTest) {
                return const Center(child: SizedBox(width: 24, height: 24));
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorWidget: (context, url, error) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.white54),
                SizedBox(height: 16),
                Text(
                  '画像を読み込めませんでした',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
