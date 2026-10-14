import 'package:flutter/material.dart';
import '../../../../../core/media/interface/widgets/app_cached_network_image.dart';
import '../../../../auth/interface/views/widgets/c_card_full_screen_viewer.dart';

/// ダイブログ詳細画面用の水中写真ギャラリーウィジェット
class DiveLogPhotoGalleryWidget extends StatelessWidget {
  final List<String> photoUrls;
  final String locationName;

  const DiveLogPhotoGalleryWidget({
    super.key,
    required this.photoUrls,
    this.locationName = '',
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '水中写真・思い出ギャラリー',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${photoUrls.length}枚',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // 写真一覧サムネイル（Wrapで横溢れ防止）
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < photoUrls.length; i++)
                  _buildPhotoThumbnail(
                    context: context,
                    url: photoUrls[i],
                    index: i,
                    total: photoUrls.length,
                    colorScheme: colorScheme,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail({
    required BuildContext context,
    required String url,
    required int index,
    required int total,
    required ColorScheme colorScheme,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 狭小画面や枚数に応じて柔軟に幅を調整 (通常は幅95px前後)
        const itemSize = 96.0;

        return SizedBox(
          width: itemSize,
          height: itemSize,
          child: Material(
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            elevation: 1,
            child: InkWell(
              onTap: () {
                final titleText = locationName.isNotEmpty
                    ? '$locationName の写真 (${index + 1}/$total)'
                    : '水中写真 (${index + 1}/$total)';
                CCardFullScreenViewer.show(
                  context: context,
                  imageUrl: url,
                  title: titleText,
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppCachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                  ),
                  // 右下の拡大ヒントアイコン
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
