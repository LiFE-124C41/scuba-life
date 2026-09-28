import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_schedule.dart';
import '../controllers/schedule_controller.dart';
import 'widgets/calendar_view.dart';
import 'widgets/schedule_detail_sheet.dart';
import 'widgets/schedule_form_dialog.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scheduleCalendarProvider);
    final notifier = ref.read(scheduleCalendarProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビング予定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () => notifier.loadSchedules(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.schedules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラーが発生しました: ${state.error}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => notifier.loadSchedules(),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          final selectedDate = state.selectedDate;
          final schedulesForSelectedDate = state.selectedDateSchedules;
          final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
          final weekdayStr = weekdayNames[selectedDate.weekday - 1];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カレンダーウィジェット
                CalendarView(
                  focusedMonth: state.focusedMonth,
                  selectedDate: selectedDate,
                  hasSchedule: (date) => state.hasScheduleOn(date),
                  scheduleCount: (date) => state.scheduleCountOn(date),
                  onDateSelected: (date) => notifier.selectDate(date),
                  onPreviousMonth: () => notifier.previousMonth(),
                  onNextMonth: () => notifier.nextMonth(),
                  onToday: () => notifier.goToToday(),
                ),

                const SizedBox(height: 8),

                // 選択日付ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日 ($weekdayStr) の予定',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Badge(
                        label: Text('${schedulesForSelectedDate.length}件'),
                        backgroundColor: schedulesForSelectedDate.isNotEmpty
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                ),

                // 選択日付の予定リストまたは空状態
                if (schedulesForSelectedDate.isEmpty)
                  _buildEmptyState(context, notifier, selectedDate)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: schedulesForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final item = schedulesForSelectedDate[index];
                      return _buildScheduleCard(context, notifier, item);
                    },
                  ),

                const SizedBox(height: 80), // FAB用の余白
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('予定を追加'),
        onPressed: () {
          ScheduleFormDialog.show(
            context,
            initialDate: state.selectedDate,
            onSave: (newSchedule) {
              notifier.addSchedule(newSchedule);
            },
          );
        },
      ),
    );
  }

  /// 該当日に予定がない場合の表示
  Widget _buildEmptyState(
    BuildContext context,
    ScheduleCalendarNotifier notifier,
    DateTime selectedDate,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.beach_access_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'この日のダイビング予定はありません',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('この日に予定を追加'),
            onPressed: () {
              ScheduleFormDialog.show(
                context,
                initialDate: selectedDate,
                onSave: (newSchedule) {
                  notifier.addSchedule(newSchedule);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  /// 予定カード（タップで詳細シートを表示）
  Widget _buildScheduleCard(
    BuildContext context,
    ScheduleCalendarNotifier notifier,
    DiveSchedule item,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.primary.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // タップで詳細ボトムシートを表示
          ScheduleDetailSheet.show(
            context,
            schedule: item,
            onDelete: () {
              notifier.deleteSchedule(item.id);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.scuba_diving,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.place, size: 16, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.destination,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.storefront, size: 16, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.diveShop,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.plannedDivesCount}ダイブ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.memo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'メモ: ${item.memo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
