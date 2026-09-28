import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/dive_log_controller.dart';
import 'dive_log_detail_page.dart';
import 'dive_log_form_page.dart';

/// ログブック一覧画面（Riverpod ConsumerWidget）
class DiveLogPage extends ConsumerWidget {
  const DiveLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diveLogsAsync = ref.watch(diveLogListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビングログ'),
      ),
      body: diveLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('エラーが発生しました: $err'),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.scuba_diving,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  const Text('ログがまだありません'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openAddLog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('最初のログを記録'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final log = logs[index];
              final theme = Theme.of(context);
              final dateStr =
                  '${log.date.year}/${log.date.month.toString().padLeft(2, '0')}/${log.date.day.toString().padLeft(2, '0')}';

              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DiveLogDetailPage(logId: log.id),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1行目: ポイント名 ＋ 5段階評価
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.location,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < log.rating ? Icons.star : Icons.star_border,
                                size: 16,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // 2行目: 日付 ＋ 最大深度 ＋ 矢印アイコン
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.arrow_downward, size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            '最大 ${log.maxDepthMeter}m',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddLog(context),
        icon: const Icon(Icons.add),
        label: const Text('ログ記録'),
      ),
    );
  }

  void _openAddLog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const DiveLogFormPage(),
      ),
    );
  }
}
