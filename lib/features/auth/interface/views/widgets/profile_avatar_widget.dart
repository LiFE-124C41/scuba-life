import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/media/domain/services/image_picker_service.dart';
import '../../../../../core/media/interface/media_providers.dart';
import '../../../../../core/media/interface/widgets/app_cached_network_image.dart';
import '../../../domain/entities/user_account.dart';
import '../../controllers/user_profile_controller.dart';
import 'c_card_full_screen_viewer.dart';

/// プロフィール写真（アバター）の表示・変更・削除コンポーネント
class ProfileAvatarWidget extends ConsumerStatefulWidget {
  final UserAccount user;
  final double radius;

  const ProfileAvatarWidget({
    super.key,
    required this.user,
    this.radius = 44,
  });

  @override
  ConsumerState<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends ConsumerState<ProfileAvatarWidget> {
  bool _isUploading = false;

  Future<void> _showActionSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasPhoto = widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.account_circle_outlined, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'プロフィール写真の変更',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('カメラで撮影'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('写真ライブラリから選択'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              if (hasPhoto) ...[
                ListTile(
                  leading: const Icon(Icons.fullscreen_outlined),
                  title: const Text('写真を拡大表示'),
                  onTap: () => Navigator.of(context).pop('view'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: colorScheme.error),
                  title: Text(
                    'プロフィール写真を削除',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'camera':
        await _pickAndUploadImage(AppImageSource.camera);
        break;
      case 'gallery':
        await _pickAndUploadImage(AppImageSource.gallery);
        break;
      case 'view':
        _viewFullScreen();
        break;
      case 'delete':
        await _confirmAndDeletePhoto();
        break;
    }
  }

  Future<void> _pickAndUploadImage(AppImageSource source) async {
    setState(() => _isUploading = true);
    try {
      final picker = ref.read(imagePickerServiceProvider);
      final bytes = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (bytes != null && mounted) {
        final notifier = ref.read(userProfileControllerProvider.notifier);
        final success = await notifier.uploadAvatarImage(
          userId: widget.user.id,
          imageBytes: bytes,
        );

        if (!mounted) return;
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('プロフィール写真を更新しました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('プロフィール写真のアップロードに失敗しました'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _confirmAndDeletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真の削除確認'),
        content: const Text('設定済みのプロフィール写真を削除しますか？'),
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

    if (confirmed == true && mounted) {
      final notifier = ref.read(userProfileControllerProvider.notifier);
      final success = await notifier.deleteAvatarImage(userId: widget.user.id);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィール写真を削除しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('プロフィール写真の削除に失敗しました'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _viewFullScreen() {
    final photoUrl = widget.user.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return;

    CCardFullScreenViewer.show(
      context: context,
      imageUrl: photoUrl,
      title: 'プロフィール写真',
      onDelete: _confirmAndDeletePhoto,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = widget.radius * 2;
    final hasPhoto = widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty;

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // アバター画像本体
          InkWell(
            onTap: _isUploading ? null : () => _showActionSheet(context),
            borderRadius: BorderRadius.circular(widget.radius),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      AppCachedNetworkImage(
                        imageUrl: widget.user.photoUrl!,
                        fit: BoxFit.cover,
                        width: size,
                        height: size,
                      )
                    else
                      Container(
                        color: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person,
                          size: widget.radius * 1.2,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),

                    // アップロード中のスピナーオーバーレイ
                    if (_isUploading)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 右下カメラバッジ（タップでアクションシート起動）
          Positioned(
            bottom: -2,
            right: -2,
            child: Material(
              color: colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: _isUploading ? null : () => _showActionSheet(context),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Icon(
                    hasPhoto ? Icons.edit : Icons.camera_alt,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
