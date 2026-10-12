import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../my_gear/domain/entities/gear_item.dart';
import '../../../my_gear/interface/controllers/gear_controller.dart';
import '../../domain/entities/dive_schedule.dart';
import '../controllers/schedule_controller.dart';

/// 今回の予定に持参する機材を選択・編集する画面
class ScheduleGearSelectionPage extends ConsumerStatefulWidget {
  final DiveSchedule schedule;

  const ScheduleGearSelectionPage({
    super.key,
    required this.schedule,
  });

  @override
  ConsumerState<ScheduleGearSelectionPage> createState() => _ScheduleGearSelectionPageState();
}

class _ScheduleGearSelectionPageState extends ConsumerState<ScheduleGearSelectionPage> {
  late Set<String> _selectedIds;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final currentTarget = widget.schedule.targetGearIds;
    if (currentTarget != null) {
      _selectedIds = Set<String>.from(currentTarget);
      _initialized = true;
    } else {
      _selectedIds = <String>{};
    }
  }

  void _ensureInitialized(List<GearItem> allGears) {
    if (!_initialized && allGears.isNotEmpty) {
      _selectedIds = allGears.map((g) => g.id).toSet();
      _initialized = true;
    }
  }

  void _toggleGear(String gearId) {
    setState(() {
      if (_selectedIds.contains(gearId)) {
        _selectedIds.remove(gearId);
      } else {
        _selectedIds.add(gearId);
      }
    });
  }

  void _selectAll(List<GearItem> allGears) {
    setState(() {
      _selectedIds = allGears.map((g) => g.id).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _save() async {
    final selectedList = _selectedIds.toList();
    await ref
        .read(scheduleCalendarProvider.notifier)
        .updateTargetGearIds(widget.schedule.id, selectedList);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('持参機材を更新しました（${selectedList.length}点選択）'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gearState = ref.watch(gearListNotifierProvider);
    final allGears = gearState.allItems;

    _ensureInitialized(allGears);

    final isAllSelected = allGears.isNotEmpty && _selectedIds.length == allGears.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('持参機材の選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              widget.schedule.title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (allGears.isNotEmpty)
            TextButton(
              onPressed: () {
                if (isAllSelected) {
                  _deselectAll();
                } else {
                  _selectAll(allGears);
                }
              },
              child: Text(isAllSelected ? '全解除' : '全選択'),
            ),
        ],
      ),
      body: allGears.isEmpty
          ? _buildEmptyView(context)
          : Column(
              children: [
                _buildGuideBanner(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: allGears.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final gear = allGears[index];
                      final isSelected = _selectedIds.contains(gear.id);
                      return _buildGearTile(context, gear, isSelected);
                    },
                  ),
                ),
                _buildBottomBar(context, allGears.length),
              ],
            ),
    );
  }

  Widget _buildGuideBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '今回持参する機材を選択してください。未選択の機材はチェックリストから除外され、準備完了の達成率にも影響しません。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGearTile(BuildContext context, GearItem gear, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _toggleGear(gear.id),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleGear(gear.id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 8),
            Icon(
              _getCategoryIcon(gear.category),
              size: 22,
              color: isSelected ? colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        gear.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? null : Colors.grey.shade600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          gear.category.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (gear.brand.isNotEmpty || gear.model.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [gear.brand, gear.model].where((s) => s.isNotEmpty).join(' / '),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int totalCount) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedCount = _selectedIds.length;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount / $totalCount 点 選択中',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    selectedCount == 0 ? '持参機材なし' : 'チェックリストに反映されます',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('決定する'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'マイ機材が登録されていません',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '機材管理からマイ機材を登録すると、今回の予定に持参する機材を選択できるようになります。',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
        return Icons.inventory_2_outlined;
    }
  }
}
