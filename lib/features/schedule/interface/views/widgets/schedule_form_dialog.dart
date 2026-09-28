import 'package:flutter/material.dart';
import '../../../domain/entities/dive_schedule.dart';

/// 新規ダイビング予定登録用ダイアログ
class ScheduleFormDialog extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DiveSchedule> onSave;

  const ScheduleFormDialog({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime initialDate,
    required ValueChanged<DiveSchedule> onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ScheduleFormDialog(
        initialDate: initialDate,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _diveShopController;
  late final TextEditingController _memoController;
  late DateTime _selectedDate;
  int _divesCount = 2;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _titleController = TextEditingController();
    _destinationController = TextEditingController();
    _diveShopController = TextEditingController();
    _memoController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _diveShopController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final schedule = DiveSchedule(
        id: 'sch-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        eventDate: _selectedDate,
        destination: _destinationController.text.trim(),
        diveShop: _diveShopController.text.trim().isEmpty
            ? 'セルフ / 未定'
            : _diveShopController.text.trim(),
        plannedDivesCount: _divesCount,
        memo: _memoController.text.trim(),
      );
      widget.onSave(schedule);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ダイビング予定を追加'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 360,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '予定タイトル *',
                    hintText: '例: 伊豆海洋公園 ファンダイビング',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'タイトルを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month, color: Colors.blue),
                  title: const Text('日程'),
                  subtitle: Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('変更'),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _destinationController,
                  decoration: const InputDecoration(
                    labelText: '目的地 / ポイント *',
                    hintText: '例: 西伊豆 大瀬崎',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return '目的地を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diveShopController,
                  decoration: const InputDecoration(
                    labelText: '利用ダイブショップ',
                    hintText: '例: オーシャンダイブ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('予定本数: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _divesCount,
                      items: [1, 2, 3, 4, 5].map((cnt) {
                        return DropdownMenuItem<int>(
                          value: cnt,
                          child: Text('$cnt 本'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _divesCount = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'メモ・持ち物',
                    hintText: '例: 水中カメラ準備、集合時間8:30など',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('登録する'),
        ),
      ],
    );
  }
}
