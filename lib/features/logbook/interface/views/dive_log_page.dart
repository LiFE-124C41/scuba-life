import 'package:flutter/material.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/repositories/dive_log_repository.dart';
import '../../infrastructure/repositories/in_memory_dive_log_repository.dart';
import '../../usecase/get_dive_logs.dart';
import '../../usecase/save_dive_log.dart';
import '../../../../core/usecase/usecase.dart';

/// ログブック一覧・記録画面
class DiveLogPage extends StatefulWidget {
  final DiveLogRepository? repository;

  const DiveLogPage({super.key, this.repository});

  @override
  State<DiveLogPage> createState() => _DiveLogPageState();
}

class _DiveLogPageState extends State<DiveLogPage> {
  late final DiveLogRepository _repository;
  late final GetDiveLogs _getDiveLogs;
  late final SaveDiveLog _saveDiveLog;

  List<DiveLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryDiveLogRepository();
    _getDiveLogs = GetDiveLogs(_repository);
    _saveDiveLog = SaveDiveLog(_repository);
    _loadSampleDataAndFetch();
  }

  Future<void> _loadSampleDataAndFetch() async {
    // 初回サンプルログを追加
    final existing = await _getDiveLogs(const NoParams());
    if (existing.isEmpty) {
      await _saveDiveLog(
        DiveLog(
          id: 'log-001',
          entryTime: DateTime.now().subtract(const Duration(hours: 3)),
          exitTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
          maxDepthMeter: 18.5,
          avgDepthMeter: 12.0,
          startPressureBar: 200,
          endPressureBar: 50,
          location: '伊豆・大瀬崎（湾内）',
          notes: '透明度良好。ミノカサゴ、クマノミのペアを観察。',
        ),
      );
    }
    final logs = await _getDiveLogs(const NoParams());
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビングログ'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('ログがまだありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
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
                ),
    );
  }
}
