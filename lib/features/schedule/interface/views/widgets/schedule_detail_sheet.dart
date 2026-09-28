import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../logbook/domain/entities/dive_log.dart';
import '../../../../logbook/interface/controllers/dive_log_controller.dart';
import '../../../../logbook/interface/views/dive_log_detail_page.dart';
import '../../../../logbook/interface/views/dive_log_form_page.dart';
import '../../../domain/entities/dive_schedule.dart';

/// 予定の詳細情報を表示するボトムシート
class ScheduleDetailSheet extends ConsumerWidget {
  final DiveSchedule schedule;
  final VoidCallback onDelete;

  const ScheduleDetailSheet({
    super.key,
    required this.schedule,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required DiveSchedule schedule,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleDetailSheet(
        schedule: schedule,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = schedule.eventDate;
    final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final weekdayStr = weekdayNames[date.weekday - 1];

    final logsAsync = ref.watch(diveLogListProvider);
    final linkedLogs = logsAsync.maybeWhen(
      data: (logs) => logs.where((l) => l.scheduleId == schedule.id).toList(),
      orElse: () => <DiveLog>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ドラッグハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // タイトル & アクション
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    schedule.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: '予定を削除',
                  onPressed: () {
                    _showDeleteConfirmDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基本情報カード
            Card(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.calendar_month,
                      label: '日程',
                      value: '${date.year}年${date.month}月${date.day}日 ($weekdayStr)',
                      color: colorScheme.primary,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.place,
                      label: '目的地 / ポイント',
                      value: schedule.destination,
                      color: Colors.teal,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.storefront,
                      label: '利用ダイブショップ',
                      value: schedule.diveShop,
                      color: Colors.indigo,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.scuba_diving,
                      label: '予定ダイビング数',
                      value: '${schedule.plannedDivesCount} ダイブ',
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ),

            if (schedule.memo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'メモ・準備事項',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  schedule.memo,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 連携機能: この予定に紐付くダイビングログセクション
            Row(
              children: [
                Icon(Icons.book, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '記録済みダイビングログ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  label: Text('${linkedLogs.length}件'),
                  backgroundColor: linkedLogs.isNotEmpty
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (linkedLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
                ),
                child: Column(
                  children: [
                    Text(
                      'この予定に紐付くログはまだ記録されていません',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('この予定からログを記録する'),
                      onPressed: () {
                        Navigator.of(context).pop(); // シートを閉じる
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DiveLogFormPage(initialSchedule: schedule),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...linkedLogs.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final log = entry.value;
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.primary.withAlpha(60)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '#$index',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          log.location,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '水深: ${log.maxDepthMeter}m / 時間: ${log.bottomTimeMinutes}分 / 評価: ★${log.rating}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop(); // シートを閉じる
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DiveLogDetailPage(logId: log.id),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('さらにこの予定のログを追加'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DiveLogFormPage(initialSchedule: schedule),
                        ),
                      );
                    },
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('予定の削除'),
        content: Text('「${schedule.title}」の予定を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // ダイアログ閉じる
              Navigator.of(context).pop(); // シート閉じる
              onDelete();
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }
}
