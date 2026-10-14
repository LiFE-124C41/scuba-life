import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/media/domain/services/image_picker_service.dart';
import '../../../../../core/media/interface/media_providers.dart';
import '../../../../../core/media/interface/widgets/app_cached_network_image.dart';
import '../../../domain/entities/user_account.dart';
import '../../controllers/user_profile_controller.dart';
import 'c_card_full_screen_viewer.dart';

/// Cカード写真（表面・裏面）の電子ライセンス証カードコンポーネント
class CCardImageCard extends ConsumerStatefulWidget {
  final UserAccount user;

  const CCardImageCard({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<CCardImageCard> createState() => _CCardImageCardState();
}

class _CCardImageCardState extends ConsumerState<CCardImageCard> {
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;

  Future<void> _pickAndUploadImage({required bool isFront}) async {
    final source = await showModalBottomSheet<AppImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                isFront ? 'Cカード (表面) の写真を選択' : 'Cカード (裏面) の写真を選択',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('カメラで撮影'),
              onTap: () => Navigator.of(context).pop(AppImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('写真ライブラリから選択'),
              onTap: () => Navigator.of(context).pop(AppImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() {
      if (isFront) {
        _isUploadingFront = true;
      } else {
        _isUploadingBack = true;
      }
    });

    try {
      final picker = ref.read(imagePickerServiceProvider);
      final bytes = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (bytes != null && mounted) {
        final notifier = ref.read(userProfileControllerProvider.notifier);
        final success = await notifier.uploadCCardImage(
          userId: widget.user.id,
          imageBytes: bytes,
          isFront: isFront,
        );

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFront ? 'Cカード表面の写真を登録しました' : 'Cカード裏面の写真を登録しました',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('写真のアップロードに失敗しました'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isFront) {
            _isUploadingFront = false;
          } else {
            _isUploadingBack = false;
          }
        });
      }
    }
  }

  Future<void> _deleteImage({required bool isFront}) async {
    final notifier = ref.read(userProfileControllerProvider.notifier);
    final success = await notifier.deleteCCardImage(
      userId: widget.user.id,
      isFront: isFront,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFront ? 'Cカード表面の写真を削除しました' : 'Cカード裏面の写真を削除しました',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行
            Row(
              children: [
                Icon(
                  Icons.photo_camera_front_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cカード写真 (電子ライセンス証)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ショップ受付時に提示できる写真を保管できます',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 表面・裏面スロット（レスポンシブ配置）
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 380;

                final frontSlot = _buildSlot(
                  context,
                  title: '表面',
                  imageUrl: widget.user.cCardFrontUrl,
                  isUploading: _isUploadingFront,
                  onTapAdd: () => _pickAndUploadImage(isFront: true),
                  onDelete: () => _deleteImage(isFront: true),
                );

                final backSlot = _buildSlot(
                  context,
                  title: '裏面',
                  imageUrl: widget.user.cCardBackUrl,
                  isUploading: _isUploadingBack,
                  onTapAdd: () => _pickAndUploadImage(isFront: false),
                  onDelete: () => _deleteImage(isFront: false),
                );

                if (isNarrow) {
                  // 小型端末（幅380px未満）は縦並びで表示
                  return Column(
                    children: [
                      frontSlot,
                      const SizedBox(height: 12),
                      backSlot,
                    ],
                  );
                } else {
                  // 通常端末は横並び（Row + Expanded）で等幅配置
                  return Row(
                    children: [
                      Expanded(child: frontSlot),
                      const SizedBox(width: 12),
                      Expanded(child: backSlot),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context, {
    required String title,
    required String? imageUrl,
    required bool isUploading,
    required VoidCallback onTapAdd,
    required VoidCallback onDelete,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return AspectRatio(
      aspectRatio: 1.58, // クレジットカード規格アスペクト比
      child: Container(
        decoration: BoxDecoration(
          color: hasImage
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasImage
                ? colorScheme.outline.withValues(alpha: 0.3)
                : colorScheme.outlineVariant,
            style: hasImage ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage) ...[
                // 画像表示
                InkWell(
                  onTap: () {
                    CCardFullScreenViewer.show(
                      context: context,
                      imageUrl: imageUrl,
                      title: 'Cカード写真 ($title)',
                      onDelete: onDelete,
                    );
                  },
                  child: AppCachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
                // タイトルバッジ (左上)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // 拡大・詳細ヒント (右下)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ] else ...[
                // 未登録スロット
                InkWell(
                  onTap: onTapAdd,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 28,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$titleを登録',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // アップロード中のスピナーオーバーレイ
              if (isUploading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
