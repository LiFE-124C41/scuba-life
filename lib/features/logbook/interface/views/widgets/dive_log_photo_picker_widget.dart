import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/media/domain/services/image_picker_service.dart';
import '../../../../../core/media/interface/media_providers.dart';
import '../../../../../core/media/interface/widgets/app_cached_network_image.dart';
import '../../../../auth/interface/controllers/auth_controller.dart';
import '../../controllers/dive_log_controller.dart';
import '../../../usecase/upload_dive_log_photo.dart';
import '../../../usecase/delete_dive_log_photo.dart';
import '../../../../auth/interface/views/widgets/c_card_full_screen_viewer.dart';

/// ログブック作成・編集画面用の水中写真ピッカーウィジェット
class DiveLogPhotoPickerWidget extends ConsumerStatefulWidget {
  final String logId;
  final List<String> initialPhotoUrls;
  final ValueChanged<List<String>> onPhotosChanged;
  final int maxPhotos;

  const DiveLogPhotoPickerWidget({
    super.key,
    required this.logId,
    required this.initialPhotoUrls,
    required this.onPhotosChanged,
    this.maxPhotos = 5,
  });

  @override
  ConsumerState<DiveLogPhotoPickerWidget> createState() => _DiveLogPhotoPickerWidgetState();
}

class _DiveLogPhotoPickerWidgetState extends ConsumerState<DiveLogPhotoPickerWidget> {
  late List<String> _photoUrls;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _photoUrls = List.from(widget.initialPhotoUrls);
  }

  Future<void> _showPickSourceModal() async {
    if (_photoUrls.length >= widget.maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('写真は最大${widget.maxPhotos}枚まで登録できます')),
      );
      return;
    }

    final source = await showModalBottomSheet<AppImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.photo_camera_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '写真を追加 (残り${widget.maxPhotos - _photoUrls.length}枚)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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

    await _pickAndUploadPhoto(source);
  }

  Future<void> _pickAndUploadPhoto(AppImageSource source) async {
    final authUser = ref.read(authStateProvider).asData?.value;
    final userId = authUser?.id ?? 'anonymous';

    setState(() => _isUploading = true);

    try {
      final picker = ref.read(imagePickerServiceProvider);
      final bytes = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (bytes != null && mounted) {
        final uploadUseCase = ref.read(uploadDiveLogPhotoUseCaseProvider);
        final url = await uploadUseCase(UploadDiveLogPhotoParams(
          userId: userId,
          logId: widget.logId,
          imageBytes: bytes,
        ));

        if (!mounted) return;
        setState(() {
          _photoUrls.add(url);
        });
        widget.onPhotosChanged(_photoUrls);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('写真を追加しました')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('写真のアップロードに失敗しました: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      final removedUrl = _photoUrls.removeAt(index);
      widget.onPhotosChanged(_photoUrls);

      // 非同期で Storage の画像も削除を試みる
      ref.read(deleteDiveLogPhotoUseCaseProvider)(
        DeleteDiveLogPhotoParams(photoUrl: removedUrl),
      );
    });
  }

  void _previewPhoto(String url, int index) {
    CCardFullScreenViewer.show(
      context: context,
      imageUrl: url,
      title: '水中写真 (${index + 1}/${_photoUrls.length})',
      onDelete: () => _removePhoto(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.photo_library_outlined, size: 18, color: colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  '水中写真・思い出写真',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              '${_photoUrls.length}/${widget.maxPhotos}枚',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Wrap でサムネイルを配置（GEMINI.md ルール: 横溢れ防止）
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // 登録済みサムネイル一覧
            for (int i = 0; i < _photoUrls.length; i++)
              _buildThumbnail(
                url: _photoUrls[i],
                index: i,
                colorScheme: colorScheme,
              ),

            // 追加スロットボタン (上限未満時)
            if (_photoUrls.length < widget.maxPhotos)
              _buildAddButton(
                colorScheme: colorScheme,
                theme: theme,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail({
    required String url,
    required int index,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 画像本体
          InkWell(
            onTap: () => _previewPhoto(url, index),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppCachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: 78,
                  height: 78,
                ),
              ),
            ),
          ),

          // 削除ボタン (右上の丸バッジ)
          Positioned(
            top: -6,
            right: -6,
            child: Material(
              color: colorScheme.error,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: () => _removePhoto(index),
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: _isUploading ? null : _showPickSourceModal,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: _isUploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 24,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '追加',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
