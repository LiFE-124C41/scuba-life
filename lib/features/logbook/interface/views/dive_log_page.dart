import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../controllers/dive_log_controller.dart';

/// ログブック一覧・記録画面（Riverpod ConsumerWidget）
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
            return const Center(child: Text('ログがまだありません'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final sac = log.calculateSacRate();
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            log.location,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Chip(
                            label: Text('${log.bottomTimeMinutes}分'),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最大水深: ${log.maxDepthMeter}m / 平均: ${log.avgDepthMeter}m',
                      ),
                      Text(
                        '残圧: ${log.startPressureBar.toInt()} → ${log.endPressureBar.toInt()} bar (消費: ${log.consumedPressureBar.toInt()} bar)',
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SACレート: ${sac.toStringAsFixed(1)} L/min',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${log.entryTime.month}/${log.entryTime.day} ${log.entryTime.hour}:${log.entryTime.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (log.notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          log.notes,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLogDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLogDialog(BuildContext context, WidgetRef ref) {
    final locationController = TextEditingController(text: '富戸・ヨコバマ');
    final maxDepthController = TextEditingController(text: '21.0');
    final avgDepthController = TextEditingController(text: '14.0');
    final startPressController = TextEditingController(text: '200');
    final endPressController = TextEditingController(text: '60');
    final notesController = TextEditingController(text: 'アオリイカの産卵礁を確認。水温快適。');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('クイックログ追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'ポイント名'),
                ),
                TextField(
                  controller: maxDepthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '最大水深 (m)'),
                ),
                TextField(
                  controller: avgDepthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '平均水深 (m)'),
                ),
                TextField(
                  controller: startPressController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '開始圧 (bar)'),
                ),
                TextField(
                  controller: endPressController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '終了圧 (bar)'),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'メモ'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final newLog = DiveLog(
                  id: 'log-${DateTime.now().millisecondsSinceEpoch}',
                  entryTime: DateTime.now().subtract(const Duration(minutes: 50)),
                  exitTime: DateTime.now(),
                  maxDepthMeter: double.tryParse(maxDepthController.text) ?? 18.0,
                  avgDepthMeter: double.tryParse(avgDepthController.text) ?? 12.0,
                  startPressureBar: double.tryParse(startPressController.text) ?? 200,
                  endPressureBar: double.tryParse(endPressController.text) ?? 50,
                  location: locationController.text.trim(),
                  notes: notesController.text.trim(),
                );
                ref.read(diveLogListProvider.notifier).addLog(newLog);
                Navigator.of(ctx).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}
