import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../controllers/dive_log_controller.dart';
import 'dive_log_form_page.dart';
import '../../../schedule/interface/controllers/schedule_controller.dart';
import '../../../schedule/interface/views/widgets/schedule_detail_sheet.dart';
import 'package:latlong2/latlong.dart';
import '../../../dive_spot/interface/views/widgets/spot_map_widget.dart';

/// ダイビングログ全情報閲覧用の詳細画面
class DiveLogDetailPage extends ConsumerWidget {
  final String logId;

  const DiveLogDetailPage({
    super.key,
    required this.logId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(diveLogListProvider);

    return logsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('ログ詳細')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('ログ詳細')),
        body: Center(child: Text('エラーが発生しました: $err')),
      ),
      data: (logs) {
        final log = logs.where((l) => l.id == logId).firstOrNull;

        if (log == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ログ詳細')),
            body: const Center(child: Text('該当するログが見つかりません')),
          );
        }

        final theme = Theme.of(context);
        final sac = log.calculateSacRate();

        return Scaffold(
          appBar: AppBar(
            title: Text(log.location),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: '編集',
                onPressed: () => _navigateToEdit(context, log),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. ヘッダーカード (ポイント、センター、評価、日付、目的)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              log.location,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < log.rating ? Icons.star : Icons.star_border,
                                size: 20,
                                color: Colors.amber,
                              );
                            }),
                          ),
                        ],
                      ),
                      if (log.diveCenter.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.storefront, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              log.diveCenter,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${log.date.year}年${log.date.month}月${log.date.day}日',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log.divePurpose,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (log.scheduleId != null) ...[
                        Builder(
                          builder: (context) {
                            final schedState = ref.watch(scheduleCalendarProvider);
                            final matchedSchedule = schedState.schedules
                                .where((s) => s.id == log.scheduleId)
                                .firstOrNull;
                            if (matchedSchedule == null) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: InkWell(
                                onTap: () {
                                  ScheduleDetailSheet.show(
                                    context,
                                    schedule: matchedSchedule,
                                    onDelete: () {
                                      ref
                                          .read(scheduleCalendarProvider.notifier)
                                          .deleteSchedule(matchedSchedule.id);
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.secondaryContainer
                                        .withAlpha(150),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.secondary.withAlpha(80),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.event_available,
                                          size: 16,
                                          color: theme.colorScheme.secondary),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '関連予定: ${matchedSchedule.title}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                theme.colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 12,
                                          color: theme.colorScheme.secondary),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (log.latitude != null && log.longitude != null) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            const Icon(Icons.map, size: 20, color: Color(0xFF0077B6)),
                            const SizedBox(width: 8),
                            Text(
                              'ダイビングポイントマップ',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${log.latitude!.toStringAsFixed(4)}, ${log.longitude!.toStringAsFixed(4)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 180,
                        child: SpotMapWidget(
                          points: [
                            MapPointItem(
                              id: log.id,
                              title: log.location,
                              latitude: log.latitude!,
                              longitude: log.longitude!,
                              pinColor: const Color(0xFF0077B6),
                            ),
                          ],
                          initialCenter: LatLng(log.latitude!, log.longitude!),
                          initialZoom: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // 2. 潜水データ・プロファイル (実績とSAC、計画)
              _buildSectionCard(
                context: context,
                title: 'ダイブデータ & 気圧実績',
                icon: Icons.timer,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile(
                        label: '潜水時間',
                        value: '${log.bottomTimeMinutes} 分',
                        subText: '${log.entryTime.hour}:${log.entryTime.minute.toString().padLeft(2, '0')} 〜 ${log.exitTime.hour}:${log.exitTime.minute.toString().padLeft(2, '0')}',
                        color: theme.colorScheme.primary,
                      ),
                      _buildMetricTile(
                        label: '最大水深',
                        value: '${log.maxDepthMeter} m',
                        subText: '平均: ${log.avgDepthMeter} m',
                        color: Colors.teal,
                      ),
                      _buildMetricTile(
                        label: '残圧消費',
                        value: '${log.consumedPressureBar.toInt()} bar',
                        subText: '${log.startPressureBar.toInt()} → ${log.endPressureBar.toInt()}',
                        color: Colors.deepOrange,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SACレート (水面空気消費率)',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${sac.toStringAsFixed(1)} L/min',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (log.plannedDepthMeter != null || log.plannedDurationMinutes != null || log.plannedReservePressureBar != null) ...[
                    const Divider(height: 24),
                    const Text('ダイブプラン（計画値）', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSimpleInfo('計画水深', log.plannedDepthMeter != null ? '${log.plannedDepthMeter} m' : '-'),
                        _buildSimpleInfo('計画時間', log.plannedDurationMinutes != null ? '${log.plannedDurationMinutes} 分' : '-'),
                        _buildSimpleInfo('計画残圧', log.plannedReservePressureBar != null ? '${log.plannedReservePressureBar!.toInt()} bar' : '-'),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 3. エントリー・水域・海況・環境・潮汐
              _buildSectionCard(
                context: context,
                title: 'エントリー & 海況・気象・潮汐',
                icon: Icons.waves,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleInfo('エントリー', log.entryMethod),
                      _buildSimpleInfo('水域', log.waterArea),
                      _buildSimpleInfo('水質', log.waterType),
                      _buildSimpleInfo('天気', log.weather),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleInfo('気温', log.airTemp != null ? '${log.airTemp} ℃' : '-'),
                      _buildSimpleInfo(
                        '水温',
                        (log.waterTempMin != null && log.waterTempMax != null)
                            ? '${log.waterTempMin}〜${log.waterTempMax} ℃'
                            : (log.waterTempMin != null ? '${log.waterTempMin} ℃' : '-'),
                      ),
                      _buildSimpleInfo('透明度', log.visibilityMeter != null ? '${log.visibilityMeter} m' : '-'),
                      _buildSimpleInfo('潮流タイプ', log.tideType),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleInfo('水中の流れ', log.underwaterCurrent),
                      _buildSimpleInfo('水面の流れ', log.surfaceCurrent),
                    ],
                  ),
                  if (log.highTideTime1 != null || log.lowTideTime1 != null || log.highTideTime2 != null || log.lowTideTime2 != null) ...[
                    const Divider(height: 20),
                    const Text('潮汐時刻', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSimpleInfo('満潮 1', log.highTideTime1 ?? '-'),
                        _buildSimpleInfo('干潮 1', log.lowTideTime1 ?? '-'),
                        _buildSimpleInfo('満潮 2', log.highTideTime2 ?? '-'),
                        _buildSimpleInfo('干潮 2', log.lowTideTime2 ?? '-'),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 4. 機材・シリンダー・ウェイト
              _buildSectionCard(
                context: context,
                title: '器材 & シリンダー & ウェイト',
                icon: Icons.scuba_diving,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSimpleInfo('シリンダー容量', '${log.tankVolumeLiter} L'),
                      _buildSimpleInfo('材質', log.cylinderMaterial),
                      _buildSimpleInfo('ウェイト', log.weightKg != null ? '${log.weightKg} kg' : '-'),
                    ],
                  ),
                  if (log.equipment.isNotEmpty) ...[
                    const Divider(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.backpack_outlined, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            log.equipment,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 5. バディ & 出会った生物
              _buildSectionCard(
                context: context,
                title: 'バディ & 出会った生物',
                icon: Icons.people_outline,
                children: [
                  const Text('バディ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (log.buddies.isEmpty)
                    const Text('登録なし', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: log.buddies.map((buddy) {
                        return Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(buddy),
                        );
                      }).toList(),
                    ),
                  const Divider(height: 20),
                  const Text('出会った生物', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  if (log.marineLife.isEmpty)
                    const Text('登録なし', style: TextStyle(color: Colors.grey))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: log.marineLife.map((creature) {
                        return Chip(
                          avatar: const Icon(Icons.water, size: 16, color: Colors.teal),
                          label: Text(creature),
                          backgroundColor: Colors.teal.shade50,
                        );
                      }).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. メモ・感想
              if (log.notes.isNotEmpty) ...[
                _buildSectionCard(
                  context: context,
                  title: 'メモ・感想',
                  icon: Icons.notes,
                  children: [
                    Text(
                      log.notes,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // 編集ボタン
              FilledButton.icon(
                onPressed: () => _navigateToEdit(context, log),
                icon: const Icon(Icons.edit),
                label: const Text('このログを編集する'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _navigateToEdit(BuildContext context, DiveLog log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiveLogFormPage(initialLog: log),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subText,
    required Color color,
  }) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(subText, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSimpleInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
