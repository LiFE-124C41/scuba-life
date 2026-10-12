import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../dive_spot/interface/views/widgets/spot_map_widget.dart';
import '../../domain/entities/dive_log.dart';
import '../controllers/dive_log_controller.dart';
import '../controllers/dive_statistics_controller.dart';
import 'dive_log_detail_page.dart';
import 'dive_log_form_page.dart';
import 'dive_log_statistics_page.dart';
import 'widgets/dive_log_summary_card.dart';
import '../../../auth/interface/views/profile_page.dart';

/// ログブック一覧画面（リスト表示 / マップ表示 切替対応）
class DiveLogPage extends ConsumerStatefulWidget {
  const DiveLogPage({super.key});

  @override
  ConsumerState<DiveLogPage> createState() => _DiveLogPageState();
}

class _DiveLogPageState extends ConsumerState<DiveLogPage> {
  bool _isMapView = false;
  DiveLog? _selectedLogForMap;

  @override
  Widget build(BuildContext context) {
    final diveLogsAsync = ref.watch(diveLogListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビングログ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'ダイバー統計・スキルシート',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DiveLogStatisticsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_isMapView ? Icons.view_list : Icons.map_outlined),
            tooltip: _isMapView ? 'リスト表示に切替' : 'マップ表示に切替',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
                _selectedLogForMap = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'アカウント設定',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
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

          if (_isMapView) {
            return _buildMapView(context, logs);
          }

          return _buildListView(context, logs);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddLog(context),
        icon: const Icon(Icons.add),
        label: const Text('ログ記録'),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<DiveLog> logs) {
    final statsAsync = ref.watch(diveStatisticsProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: logs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          final stats = statsAsync.value;
          if (stats == null || stats.totalDives == 0) {
            return const SizedBox.shrink();
          }
          return DiveLogSummaryCard(statistics: stats);
        }

        final logIndex = index - 1;
        final log = logs[logIndex];
        final theme = Theme.of(context);
        final dateStr =
            '${log.date.year}/${log.date.month.toString().padLeft(2, '0')}/${log.date.day.toString().padLeft(2, '0')}';

        return Column(
          children: [
            InkWell(
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
                          child: Row(
                            children: [
                              if (log.latitude != null && log.longitude != null)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.place,
                                    size: 16,
                                    color: Color(0xFF0077B6),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  log.location,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
            ),
            if (logIndex < logs.length - 1)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  Widget _buildMapView(BuildContext context, List<DiveLog> logs) {
    final theme = Theme.of(context);
    // 位置情報が存在するログを抽出
    final logsWithLocation = logs
        .where((l) => l.latitude != null && l.longitude != null)
        .toList();

    if (logsWithLocation.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                '位置情報が登録されたログがありません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'ログ作成時に「ポイントマスタ」から選択すると、\n地図上にピンが表示されます。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isMapView = false;
                  });
                },
                icon: const Icon(Icons.view_list),
                label: const Text('リスト表示に戻る'),
              ),
            ],
          ),
        ),
      );
    }

    final mapPoints = logsWithLocation.map((log) {
      return MapPointItem(
        id: log.id,
        title: log.location,
        latitude: log.latitude!,
        longitude: log.longitude!,
        pinColor: _selectedLogForMap?.id == log.id
            ? Colors.deepOrange
            : const Color(0xFF0077B6),
        pinIcon: Icons.scuba_diving,
        onTap: () {
          setState(() {
            _selectedLogForMap = log;
          });
        },
      );
    }).toList();

    final centerPoint = _selectedLogForMap != null
        ? LatLng(_selectedLogForMap!.latitude!, _selectedLogForMap!.longitude!)
        : LatLng(logsWithLocation.first.latitude!, logsWithLocation.first.longitude!);

    return Stack(
      children: [
        Positioned.fill(
          child: SpotMapWidget(
            points: mapPoints,
            initialCenter: centerPoint,
            initialZoom: 9.0,
            onPointSelected: (pointItem) {
              final clicked = logsWithLocation.firstWhere((l) => l.id == pointItem.id);
              setState(() {
                _selectedLogForMap = clicked;
              });
            },
          ),
        ),
        // 選択されたログのプレビューカード
        if (_selectedLogForMap != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 84, // FABの上
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedLogForMap!.location,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _selectedLogForMap = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '日付: ${_selectedLogForMap!.date.year}/${_selectedLogForMap!.date.month}/${_selectedLogForMap!.date.day} • 最大水深: ${_selectedLogForMap!.maxDepthMeter}m',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    DiveLogDetailPage(logId: _selectedLogForMap!.id),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('詳細を見る'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
