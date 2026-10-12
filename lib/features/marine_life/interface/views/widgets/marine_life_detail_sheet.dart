import 'package:flutter/material.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/interface/views/dive_log_detail_page.dart';
import 'package:scuba_life/features/marine_life/domain/entities/marine_life_summary.dart';

/// 生き物の詳細・過去遭遇ログ一覧を表示するモーダルボトムシート
class MarineLifeDetailSheet extends StatelessWidget {
  final MarineLifeSummary summary;

  const MarineLifeDetailSheet({
    super.key,
    required this.summary,
  });

  static void show(BuildContext context, MarineLifeSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MarineLifeDetailSheet(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // ドラッグバー
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ヘッダー（生物名・遭遇回数・閉じるボタン）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.set_meal,
                        color: colorScheme.onPrimaryContainer,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '累計 ${summary.encounterCount} 回遭遇',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // コンテンツスクロール
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    // 出現月 & 場所サマリー
                    _buildOverviewCard(context),

                    const SizedBox(height: 16),

                    // 遭遇ログ一覧ヘッダー
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '遭遇ログ履歴 (${summary.encounterLogs.length}件)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 各ログのカード
                    if (summary.encounterLogs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: Text('ログデータがありません')),
                      )
                    else
                      ...summary.encounterLogs.map(
                        (log) => _buildEncounterLogItem(context, log),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withAlpha(128),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 出現月
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '出会った月:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: summary.months.map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$m月',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 出会った場所
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '出会った場所:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: summary.locations.map((loc) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withAlpha(100),
                          ),
                        ),
                        child: Text(
                          loc,
                          style: theme.textTheme.labelSmall,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            if (summary.maxDepthMeter != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '最大遭遇水深: ${summary.maxDepthMeter!.toStringAsFixed(1)} m',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEncounterLogItem(BuildContext context, DiveLog log) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateStr =
        '${log.date.year}/${log.date.month.toString().padLeft(2, '0')}/${log.date.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DiveLogDetailPage(logId: log.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateStr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'ログを見る',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      log.location,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 水深・潜水時間・水温等のバッジ
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildMiniBadge(
                    context,
                    Icons.arrow_downward,
                    '最大 ${log.maxDepthMeter.toStringAsFixed(1)}m',
                  ),
                  _buildMiniBadge(
                    context,
                    Icons.timer_outlined,
                    '${log.bottomTimeMinutes}分',
                  ),
                  if (log.waterTempMin != null)
                    _buildMiniBadge(
                      context,
                      Icons.thermostat,
                      '水温 ${log.waterTempMin!.toStringAsFixed(1)}℃',
                    ),
                  if (log.visibilityMeter != null)
                    _buildMiniBadge(
                      context,
                      Icons.visibility_outlined,
                      '透明度 ${log.visibilityMeter!.toStringAsFixed(1)}m',
                    ),
                ],
              ),
              if (log.notes.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  log.notes,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
