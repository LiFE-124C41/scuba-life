import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scuba_life/features/marine_life/interface/controllers/marine_life_controller.dart';
import 'package:scuba_life/features/marine_life/usecase/get_marine_life_summaries.dart';
import 'widgets/marine_life_card.dart';

/// 出会った生き物図鑑・検索画面
class MarineLifePage extends ConsumerStatefulWidget {
  const MarineLifePage({super.key});

  @override
  ConsumerState<MarineLifePage> createState() => _MarineLifePageState();
}

class _MarineLifePageState extends ConsumerState<MarineLifePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final marineLifeAsync = ref.watch(marineLifeListProvider);
    final filterState = ref.watch(marineLifeFilterNotifierProvider);
    final filterNotifier = ref.read(marineLifeFilterNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('生き物図鑑'),
        actions: [
          PopupMenuButton<MarineLifeSortOrder>(
            icon: const Icon(Icons.sort),
            tooltip: '並び替え',
            initialValue: filterState.sortOrder,
            onSelected: (order) {
              filterNotifier.setSortOrder(order);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: MarineLifeSortOrder.encounterCountDesc,
                child: Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 20),
                    SizedBox(width: 8),
                    Text('遭遇回数が多い順'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MarineLifeSortOrder.nameAsc,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text('名前順（五十音順）'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: MarineLifeSortOrder.recentlyEncountered,
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('直近に出会った順'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 検索バー
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '生物名やポイント名で検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          filterNotifier.setSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withAlpha(120),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                filterNotifier.setSearchQuery(value);
                setState(() {});
              },
            ),
          ),

          // 2. 出現月クイックフィルター（横スクロール）
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 13, // 0: 全て, 1〜12: 各月
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final month = isAll ? null : index;
                final isSelected = filterState.selectedMonth == month;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(isAll ? '全月' : '$month月'),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) {
                      filterNotifier.setSelectedMonth(isSelected ? null : month);
                    },
                    backgroundColor: colorScheme.surface,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant.withAlpha(100),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // 3. 一覧コンテンツ
          Expanded(
            child: marineLifeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('エラーが発生しました: $err'),
              ),
              data: (summaries) {
                if (summaries.isEmpty) {
                  return _buildEmptyState(context);
                }

                // 合計遭遇件数
                final totalEncounters = summaries.fold<int>(
                  0,
                  (sum, item) => sum + item.encounterCount,
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(marineLifeListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: summaries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // 統計ヘッダー
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, left: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '発見生物: ${summaries.length} 種',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '延べ遭遇数: $totalEncounters 回',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final item = summaries[index - 1];
                      return MarineLifeCard(summary: item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filterState = ref.watch(marineLifeFilterNotifierProvider);
    final isFiltering = _searchController.text.isNotEmpty ||
        filterState.selectedMonth != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.set_meal_outlined,
              size: 64,
              color: colorScheme.primary.withAlpha(128),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltering ? '該当する生き物が見つかりませんでした' : '記録された生き物がまだありません',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltering
                  ? '検索条件や月フィルターを変更してお試しください。'
                  : 'ダイビングログブックに出会った生物を記録すると、\nここに遭遇図鑑として自動集約されます。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (isFiltering) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  ref.read(marineLifeFilterNotifierProvider.notifier).reset();
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text('フィルターをリセット'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
