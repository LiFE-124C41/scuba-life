import 'package:flutter/material.dart';
import '../../domain/entities/dive_schedule.dart';
import '../../infrastructure/repositories/in_memory_dive_schedule_repository.dart';
import '../../usecase/get_dive_schedules.dart';
import '../../../../core/usecase/usecase.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final _getSchedules = GetDiveSchedules(InMemoryDiveScheduleRepository());
  List<DiveSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _getSchedules(const NoParams());
    if (mounted) {
      setState(() {
        _schedules = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビングスケジュール'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final item = _schedules[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.calendar_month),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('日程: ${item.eventDate.year}/${item.eventDate.month}/${item.eventDate.day}'),
                        Text('場所: ${item.destination} (${item.diveShop})'),
                        Text('予定本数: ${item.plannedDivesCount}本'),
                        if (item.memo.isNotEmpty) Text('メモ: ${item.memo}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
