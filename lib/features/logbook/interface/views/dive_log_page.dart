import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../controllers/dive_log_controller.dart';
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
                    onPressed: () => _openLogForm(context),
                    icon: const Icon(Icons.add),
                    label: const Text('最初のログを記録'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              final sac = log.calculateSacRate();
              final theme = Theme.of(context);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _openLogForm(context, log),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ヘッダー行: ポイント名 + 潜水時間バッジ + 評価
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.location,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (log.diveCenter.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      log.diveCenter,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Chip(
                                  label: Text('${log.bottomTimeMinutes}分'),
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  labelStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
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
                          ],
                        ),
                        const SizedBox(height: 8),

                        // タグ群（目的・エントリー方式・水域・潮流）
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildInfoBadge(log.divePurpose, Colors.blue.shade100, Colors.blue.shade900),
                            _buildInfoBadge('${log.entryMethod}エントリー', Colors.teal.shade100, Colors.teal.shade900),
                            _buildInfoBadge('${log.waterArea} (${log.waterType})', Colors.cyan.shade100, Colors.cyan.shade900),
                            if (log.tideType.isNotEmpty)
                              _buildInfoBadge(log.tideType, Colors.indigo.shade100, Colors.indigo.shade900),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // 主要ダイブデータ
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem('最大水深', '${log.maxDepthMeter}m'),
                                  _buildStatItem('平均水深', '${log.avgDepthMeter}m'),
                                  _buildStatItem('開始圧', '${log.startPressureBar.toInt()} bar'),
                                  _buildStatItem('終了圧', '${log.endPressureBar.toInt()} bar'),
                                ],
                              ),
                              if (log.plannedDepthMeter != null || log.plannedDurationMinutes != null) ...[
                                const Divider(height: 12),
                                Row(
                                  children: [
                                    const Text('計画: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    if (log.plannedDepthMeter != null)
                                      Text('${log.plannedDepthMeter}m ', style: const TextStyle(fontSize: 12)),
                                    if (log.plannedDurationMinutes != null)
                                      Text('/ ${log.plannedDurationMinutes}分 ', style: const TextStyle(fontSize: 12)),
                                    if (log.plannedReservePressureBar != null)
                                      Text('/ 残圧${log.plannedReservePressureBar!.toInt()}bar ', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // 海況・天候・水温
                        if (log.waterTempMin != null || log.visibilityMeter != null || log.weather.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 4),
                              Text('${log.weather} ', style: theme.textTheme.bodySmall),
                              if (log.airTemp != null) Text('気温${log.airTemp}℃ ', style: theme.textTheme.bodySmall),
                              if (log.waterTempMin != null && log.waterTempMax != null)
                                Text('水温${log.waterTempMin}〜${log.waterTempMax}℃ ', style: theme.textTheme.bodySmall)
                              else if (log.waterTempMin != null)
                                Text('水温${log.waterTempMin}℃ ', style: theme.textTheme.bodySmall),
                              if (log.visibilityMeter != null)
                                Text('透明度${log.visibilityMeter}m', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ],

                        // 出会った生物
                        if (log.marineLife.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.pets, size: 16, color: Colors.teal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  log.marineLife.join('、'),
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal.shade900),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // バディ
                        if (log.buddies.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'バディ: ${log.buddies.join(", ")}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const Divider(height: 16),

                        // フッター: SACレート & 日時
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SACレート: ${sac.toStringAsFixed(1)} L/min',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              '${log.date.year}/${log.date.month}/${log.date.day} ${log.entryTime.hour}:${log.entryTime.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),

                        if (log.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            log.notes,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openLogForm(context),
        icon: const Icon(Icons.add),
        label: const Text('ログ記録'),
      ),
    );
  }

  void _openLogForm(BuildContext context, [DiveLog? log]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiveLogFormPage(initialLog: log),
      ),
    );
  }

  Widget _buildInfoBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
