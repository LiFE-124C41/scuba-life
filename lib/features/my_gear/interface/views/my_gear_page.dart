import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gear_item.dart';
import '../controllers/gear_controller.dart';
import 'gear_detail_page.dart';
import 'gear_form_page.dart';
import 'widgets/gear_summary_card.dart';
import 'widgets/overhaul_status_badge.dart';

/// 自分の機材管理一覧ページ
class MyGearPage extends ConsumerWidget {
  const MyGearPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gearListNotifierProvider);
    final filteredItems = state.filteredItems;
    final selectedCategory = state.selectedCategory;
    final notifier = ref.read(gearListNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My機材・オーバーホール管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () => notifier.loadGear(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => notifier.loadGear(),
              child: CustomScrollView(
                slivers: [
                  // サマリーカード
                  SliverToBoxAdapter(
                    child: GearSummaryCard(state: state),
                  ),

                  // カテゴリフィルターチップ
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text('すべて'),
                              selected: selectedCategory == null,
                              onSelected: (_) {
                                notifier.setCategoryFilter(null);
                              },
                            ),
                          ),
                          ...GearCategory.values.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(cat.label),
                                selected: selectedCategory == cat,
                                onSelected: (selected) {
                                  notifier.setCategoryFilter(selected ? cat : null);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // 機材一覧リスト
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              selectedCategory == null
                                  ? '登録されている機材がありません'
                                  : '「${selectedCategory.label}」の機材はありません',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('機材を追加する'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const GearFormPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final gear = filteredItems[index];
                            return _buildGearCard(context, ref, gear);
                          },
                          childCount: filteredItems.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('機材を追加'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GearFormPage(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGearCard(BuildContext context, WidgetRef ref, GearItem gear) {
    final status = gear.calculateStatus();
    final days = gear.calculateDaysUntilOverhaul();
    final dives = gear.calculateDivesUntilOverhaul();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: status == OverhaulStatus.overdue
            ? BorderSide(color: Colors.red.shade400, width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GearDetailPage(gearId: gear.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      _getCategoryIcon(gear.category),
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gear.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (gear.brand.isNotEmpty || gear.model.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            [gear.brand, gear.model].where((s) => s.isNotEmpty).join(' / '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  OverhaulStatusBadge(gear: gear),
                ],
              ),
              if (gear.requiresOverhaul) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_month_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '次回目安: ${gear.nextOverhaulDate.year}/${gear.nextOverhaulDate.month}/${gear.nextOverhaulDate.day}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                        ),
                      ],
                    ),
                    Text(
                      days <= 0
                          ? '${-days}日 超過'
                          : 'あと $days 日',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: days <= 0
                            ? Colors.red.shade700
                            : (days <= 30 ? Colors.orange.shade800 : Colors.green.shade800),
                      ),
                    ),
                  ],
                ),
                if (gear.overhaulIntervalDives != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.scuba_diving,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'OH後潜水: ${gear.divesSinceOverhaul} / ${gear.overhaulIntervalDives}本',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                      if (dives != null)
                        Text(
                          dives <= 0 ? '${-dives}本 超過' : '残り $dives 本',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: dives <= 0 ? Colors.red.shade700 : Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GearCategory category) {
    switch (category) {
      case GearCategory.regulator:
        return Icons.water;
      case GearCategory.bcd:
        return Icons.shield;
      case GearCategory.diveComputer:
        return Icons.watch;
      case GearCategory.suit:
        return Icons.accessibility_new;
      case GearCategory.maskSnorkelFin:
        return Icons.visibility;
      case GearCategory.accessories:
        return Icons.flash_on;
    }
  }
}
