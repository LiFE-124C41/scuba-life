import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_spot.dart';
import '../controllers/dive_spot_controller.dart';

/// ダイビングポイント選択・登録モーダル
class DiveSpotSelectModal extends ConsumerStatefulWidget {
  final DiveSpot? selectedSpot;

  const DiveSpotSelectModal({super.key, this.selectedSpot});

  static Future<DiveSpot?> show(BuildContext context, {DiveSpot? selectedSpot}) {
    return showModalBottomSheet<DiveSpot>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DiveSpotSelectModal(selectedSpot: selectedSpot),
    );
  }

  @override
  ConsumerState<DiveSpotSelectModal> createState() => _DiveSpotSelectModalState();
}

class _DiveSpotSelectModalState extends ConsumerState<DiveSpotSelectModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSpotDialog() {
    final nameController = TextEditingController();
    final areaController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ダイビングポイントの登録'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'ポイント名 *',
                      hintText: '例: 大瀬崎 湾内',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'ポイント名を入力してください' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: areaController,
                    decoration: const InputDecoration(
                      labelText: 'エリア・地域名 *',
                      hintText: '例: 静岡県・西伊豆',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'エリア名を入力してください' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '緯度 (Latitude) *',
                            hintText: '例: 35.0308',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '緯度を入力';
                            }
                            final val = double.tryParse(v);
                            if (val == null || val < -90 || val > 90) {
                              return '-90〜90の数値';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: '経度 (Longitude) *',
                            hintText: '例: 138.7903',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return '経度を入力';
                            }
                            final val = double.tryParse(v);
                            if (val == null || val < -180 || val > 180) {
                              return '-180〜180';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: '見どころ・特徴（任意）',
                      hintText: '例: 水中神社やマクロ生物が豊富',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final newSpot = DiveSpot(
                    id: 'spot-${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    area: areaController.text.trim(),
                    latitude: double.parse(latController.text.trim()),
                    longitude: double.parse(lngController.text.trim()),
                    description: descController.text.trim(),
                  );
                  await ref.read(diveSpotListProvider.notifier).addSpot(newSpot);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  if (mounted) {
                    Navigator.of(context).pop(newSpot);
                  }
                }
              },
              child: const Text('登録して選択'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(diveSpotListProvider);
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
        children: [
          // 上部ドラッグハンドル
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.place, color: Color(0xFF0077B6)),
                const SizedBox(width: 8),
                Text(
                  'ダイビングポイント選択',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showAddSpotDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('新規登録'),
                ),
              ],
            ),
          ),
          // 検索バー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ポイント名やエリア名で検索...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
          // フィルターチップ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('お気に入りのみ'),
                  avatar: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_border,
                    size: 16,
                    color: _showFavoritesOnly ? Colors.amber : null,
                  ),
                  selected: _showFavoritesOnly,
                  onSelected: (val) {
                    setState(() {
                      _showFavoritesOnly = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ポイント一覧
          Expanded(
            child: spotsAsync.when(
              data: (spots) {
                var filtered = spots;
                if (_showFavoritesOnly) {
                  filtered = filtered.where((s) => s.isFavorite).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((s) =>
                          s.name.toLowerCase().contains(_searchQuery) ||
                          s.area.toLowerCase().contains(_searchQuery) ||
                          s.description.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('該当するポイントが見つかりませんでした'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _showAddSpotDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('このポイントを登録する'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final spot = filtered[index];
                    final isSelected = widget.selectedSpot?.id == spot.id;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primaryContainer,
                        foregroundColor: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onPrimaryContainer,
                        child: const Icon(Icons.place, size: 20),
                      ),
                      title: Text(
                        spot.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${spot.area} • 緯度: ${spot.latitude.toStringAsFixed(4)}, 経度: ${spot.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (spot.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              spot.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              spot.isFavorite ? Icons.star : Icons.star_border,
                              color: spot.isFavorite ? Colors.amber : Colors.grey,
                            ),
                            tooltip: 'お気に入り',
                            onPressed: () {
                              ref
                                  .read(diveSpotListProvider.notifier)
                                  .toggleFavorite(spot.id);
                            },
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop(spot);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('読み込みエラー: $err')),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
