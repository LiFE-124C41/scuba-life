import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../controllers/dive_log_controller.dart';
import '../../../schedule/domain/entities/dive_schedule.dart';
import '../../../schedule/interface/controllers/schedule_controller.dart';
import '../../../dive_spot/interface/views/dive_spot_select_modal.dart';

/// ダイビングログ新規作成・編集用フルスクリーンフォーム画面
class DiveLogFormPage extends ConsumerStatefulWidget {
  final DiveLog? initialLog;
  final DiveSchedule? initialSchedule;

  const DiveLogFormPage({
    super.key,
    this.initialLog,
    this.initialSchedule,
  });

  @override
  ConsumerState<DiveLogFormPage> createState() => _DiveLogFormPageState();
}

class _DiveLogFormPageState extends ConsumerState<DiveLogFormPage> {
  final _formKey = GlobalKey<FormState>();

  // 1. 基本情報
  String? _selectedScheduleId;
  late DateTime _selectedDate;
  late TimeOfDay _entryTime;
  late TimeOfDay _exitTime;
  late int _rating;
  late String _divePurpose;
  late String _entryMethod;
  late String _waterArea;
  late String _waterType;

  late TextEditingController _locationController;
  String? _spotId;
  double? _latitude;
  double? _longitude;
  late TextEditingController _diveCenterController;

  // 2. 深度・気圧・計画
  late TextEditingController _maxDepthController;
  late TextEditingController _avgDepthController;
  late TextEditingController _startPressureController;
  late TextEditingController _endPressureController;
  late TextEditingController _tankVolumeController;
  late String _cylinderMaterial;
  late TextEditingController _weightController;

  late TextEditingController _plannedDepthController;
  late TextEditingController _plannedDurationController;
  late TextEditingController _plannedReserveController;

  // 3. 環境・海況・潮汐
  late String _weather;
  late TextEditingController _airTempController;
  late TextEditingController _waterTempMinController;
  late TextEditingController _waterTempMaxController;
  late TextEditingController _visibilityController;
  late String _underwaterCurrent;
  late String _surfaceCurrent;
  late String _tideType;
  late TextEditingController _highTide1Controller;
  late TextEditingController _lowTide1Controller;
  late TextEditingController _highTide2Controller;
  late TextEditingController _lowTide2Controller;

  // 4. 機材・バディ・生物・メモ
  late TextEditingController _equipmentController;
  late TextEditingController _notesController;

  final List<String> _buddies = [];
  final TextEditingController _buddyInputController = TextEditingController();

  final List<String> _marineLife = [];
  final TextEditingController _marineLifeInputController = TextEditingController();

  final List<String> _divePurposes = ['ファンダイビング', '講習・教育', '体験ダイビング', '写真撮影', '調査・作業', 'その他'];
  final List<String> _entryMethods = ['ボート', 'ビーチ', 'その他'];
  final List<String> _waterAreas = ['海洋', '湖', '川', 'プール'];
  final List<String> _waterTypes = ['海水', '淡水', '汽水'];
  final List<String> _cylinderMaterials = ['スチール', 'アルミ'];
  final List<String> _weathers = ['晴れ', '曇り', '雨', '雪'];
  final List<String> _currentLevels = ['なし', '弱', '中', '強'];
  final List<String> _surfaceConditions = ['穏やか', 'さざ波', 'うねり', '白波'];
  final List<String> _tideTypes = ['大潮', '中潮', '小潮', '長潮', '若潮'];

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    final sched = widget.initialSchedule;
    final now = DateTime.now();

    _selectedScheduleId = log?.scheduleId ?? sched?.id;
    _selectedDate = log?.date ?? sched?.eventDate ?? now;
    _entryTime = log != null
        ? TimeOfDay(hour: log.entryTime.hour, minute: log.entryTime.minute)
        : TimeOfDay(hour: now.hour > 0 ? now.hour - 1 : 9, minute: 0);
    _exitTime = log != null
        ? TimeOfDay(hour: log.exitTime.hour, minute: log.exitTime.minute)
        : TimeOfDay(hour: now.hour > 0 ? now.hour - 1 : 9, minute: 45);

    _rating = log?.rating ?? 4;
    _divePurpose = log?.divePurpose ?? _divePurposes.first;
    _entryMethod = log?.entryMethod ?? _entryMethods.first;
    _waterArea = log?.waterArea ?? _waterAreas.first;
    _waterType = log?.waterType ?? _waterTypes.first;

    _locationController = TextEditingController(
      text: log?.location ?? sched?.destination ?? '',
    );
    _spotId = log?.spotId ?? sched?.spotId;
    _latitude = log?.latitude ?? sched?.latitude;
    _longitude = log?.longitude ?? sched?.longitude;
    _diveCenterController = TextEditingController(
      text: log?.diveCenter ?? sched?.diveShop ?? '',
    );

    _maxDepthController = TextEditingController(text: log != null ? log.maxDepthMeter.toString() : '18.0');
    _avgDepthController = TextEditingController(text: log != null ? log.avgDepthMeter.toString() : '12.0');
    _startPressureController = TextEditingController(text: log != null ? log.startPressureBar.toInt().toString() : '200');
    _endPressureController = TextEditingController(text: log != null ? log.endPressureBar.toInt().toString() : '50');
    _tankVolumeController = TextEditingController(text: log != null ? log.tankVolumeLiter.toString() : '10.0');
    _cylinderMaterial = log?.cylinderMaterial ?? _cylinderMaterials.first;
    _weightController = TextEditingController(text: log?.weightKg != null ? log!.weightKg.toString() : '4.0');

    _plannedDepthController = TextEditingController(text: log?.plannedDepthMeter?.toString() ?? '20.0');
    _plannedDurationController = TextEditingController(text: log?.plannedDurationMinutes?.toString() ?? '45');
    _plannedReserveController = TextEditingController(text: log?.plannedReservePressureBar?.toString() ?? '50');

    _weather = log?.weather ?? _weathers.first;
    _airTempController = TextEditingController(text: log?.airTemp?.toString() ?? '24.0');
    _waterTempMinController = TextEditingController(text: log?.waterTempMin?.toString() ?? '20.0');
    _waterTempMaxController = TextEditingController(text: log?.waterTempMax?.toString() ?? '22.5');
    _visibilityController = TextEditingController(text: log?.visibilityMeter?.toString() ?? '15.0');
    _underwaterCurrent = log?.underwaterCurrent ?? _currentLevels.first;
    _surfaceCurrent = log?.surfaceCurrent ?? _surfaceConditions.first;
    _tideType = log?.tideType ?? _tideTypes[1]; // 中潮

    _highTide1Controller = TextEditingController(text: log?.highTideTime1 ?? '06:30');
    _lowTide1Controller = TextEditingController(text: log?.lowTideTime1 ?? '12:40');
    _highTide2Controller = TextEditingController(text: log?.highTideTime2 ?? '18:50');
    _lowTide2Controller = TextEditingController(text: log?.lowTideTime2 ?? '00:30');

    _equipmentController = TextEditingController(text: log?.equipment ?? '5mmウェットスーツ, フードベスト');
    _notesController = TextEditingController(text: log?.notes ?? '');

    if (log != null) {
      _buddies.addAll(log.buddies);
      _marineLife.addAll(log.marineLife);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _diveCenterController.dispose();
    _maxDepthController.dispose();
    _avgDepthController.dispose();
    _startPressureController.dispose();
    _endPressureController.dispose();
    _tankVolumeController.dispose();
    _weightController.dispose();
    _plannedDepthController.dispose();
    _plannedDurationController.dispose();
    _plannedReserveController.dispose();
    _airTempController.dispose();
    _waterTempMinController.dispose();
    _waterTempMaxController.dispose();
    _visibilityController.dispose();
    _highTide1Controller.dispose();
    _lowTide1Controller.dispose();
    _highTide2Controller.dispose();
    _lowTide2Controller.dispose();
    _equipmentController.dispose();
    _notesController.dispose();
    _buddyInputController.dispose();
    _marineLifeInputController.dispose();
    super.dispose();
  }

  int get _calculatedDurationMinutes {
    final startMinutes = _entryTime.hour * 60 + _entryTime.minute;
    final endMinutes = _exitTime.hour * 60 + _exitTime.minute;
    final diff = endMinutes - startMinutes;
    return diff >= 0 ? diff : 0;
  }

  void _addBuddy() {
    final text = _buddyInputController.text.trim();
    if (text.isNotEmpty && !_buddies.contains(text)) {
      setState(() {
        _buddies.add(text);
        _buddyInputController.clear();
      });
    }
  }

  void _addMarineLife() {
    final text = _marineLifeInputController.text.trim();
    if (text.isNotEmpty && !_marineLife.contains(text)) {
      setState(() {
        _marineLife.add(text);
        _marineLifeInputController.clear();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickEntryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _entryTime,
    );
    if (picked != null) {
      setState(() {
        _entryTime = picked;
      });
    }
  }

  Future<void> _pickExitTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _exitTime,
    );
    if (picked != null) {
      setState(() {
        _exitTime = picked;
      });
    }
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('入力内容をご確認ください')),
      );
      return;
    }

    final entryDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _entryTime.hour,
      _entryTime.minute,
    );

    var exitDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _exitTime.hour,
      _exitTime.minute,
    );

    // 日跨ぎ対応 (終了が開始より前なら翌日とみなす)
    if (exitDateTime.isBefore(entryDateTime)) {
      exitDateTime = exitDateTime.add(const Duration(days: 1));
    }

    final maxDepth = double.tryParse(_maxDepthController.text) ?? 0.0;
    final avgDepth = double.tryParse(_avgDepthController.text) ?? 0.0;
    if (avgDepth > maxDepth) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('平均水深は最大水深以下にしてください')),
      );
      return;
    }

    final startPress = double.tryParse(_startPressureController.text) ?? 200.0;
    final endPress = double.tryParse(_endPressureController.text) ?? 50.0;
    if (startPress < endPress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開始気圧は終了気圧以上にしてください')),
      );
      return;
    }

    final waterMin = double.tryParse(_waterTempMinController.text);
    final waterMax = double.tryParse(_waterTempMaxController.text);
    if (waterMin != null && waterMax != null && waterMin > waterMax) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最低水温は最高水温以下にしてください')),
      );
      return;
    }

    final newLog = DiveLog(
      id: widget.initialLog?.id ?? 'log-${DateTime.now().millisecondsSinceEpoch}',
      scheduleId: _selectedScheduleId,
      date: _selectedDate,
      entryTime: entryDateTime,
      exitTime: exitDateTime,
      location: _locationController.text.trim(),
      spotId: _spotId,
      latitude: _latitude,
      longitude: _longitude,
      diveCenter: _diveCenterController.text.trim(),
      rating: _rating,
      divePurpose: _divePurpose,
      entryMethod: _entryMethod,
      waterArea: _waterArea,
      waterType: _waterType,
      maxDepthMeter: maxDepth,
      avgDepthMeter: avgDepth,
      startPressureBar: startPress,
      endPressureBar: endPress,
      tankVolumeLiter: double.tryParse(_tankVolumeController.text) ?? 10.0,
      cylinderMaterial: _cylinderMaterial,
      weightKg: double.tryParse(_weightController.text),
      plannedDepthMeter: double.tryParse(_plannedDepthController.text),
      plannedDurationMinutes: int.tryParse(_plannedDurationController.text),
      plannedReservePressureBar: double.tryParse(_plannedReserveController.text),
      weather: _weather,
      airTemp: double.tryParse(_airTempController.text),
      waterTempMin: waterMin,
      waterTempMax: waterMax,
      visibilityMeter: double.tryParse(_visibilityController.text),
      underwaterCurrent: _underwaterCurrent,
      surfaceCurrent: _surfaceCurrent,
      tideType: _tideType,
      highTideTime1: _highTide1Controller.text.trim().isNotEmpty ? _highTide1Controller.text.trim() : null,
      lowTideTime1: _lowTide1Controller.text.trim().isNotEmpty ? _lowTide1Controller.text.trim() : null,
      highTideTime2: _highTide2Controller.text.trim().isNotEmpty ? _highTide2Controller.text.trim() : null,
      lowTideTime2: _lowTide2Controller.text.trim().isNotEmpty ? _lowTide2Controller.text.trim() : null,
      buddies: List.unmodifiable(_buddies),
      marineLife: List.unmodifiable(_marineLife),
      equipment: _equipmentController.text.trim(),
      notes: _notesController.text.trim(),
    );

    ref.read(diveLogListProvider.notifier).addLog(newLog);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ダイビングログを保存しました')),
    );
    Navigator.of(context).pop();
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
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
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final scheduleState = ref.watch(scheduleCalendarProvider);
    final availableSchedules = [...scheduleState.schedules];
    if (widget.initialSchedule != null &&
        !availableSchedules.any((s) => s.id == widget.initialSchedule!.id)) {
      availableSchedules.add(widget.initialSchedule!);
    }
    final effectiveScheduleId = availableSchedules.any((s) => s.id == _selectedScheduleId)
        ? _selectedScheduleId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialLog == null ? 'ログを追加' : 'ログを編集'),
        actions: [
          IconButton(
            onPressed: _saveForm,
            icon: const Icon(Icons.check),
            tooltip: '保存',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // 1. 基本情報 & 評価
            _buildSectionCard(
              context: context,
              title: '基本情報 & 評価',
              icon: Icons.star_outline,
              children: [
                // 予定連携ドロップダウン
                DropdownButtonFormField<String?>(
                  initialValue: effectiveScheduleId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '関連する予定（トリップ/ツアー）',
                    prefixIcon: Icon(Icons.event_outlined),
                    helperText: '予定を選択すると日付・ポイント・ショップが自動反映されます',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('連携なし（単独ログ）'),
                    ),
                    ...availableSchedules.map((s) {
                      return DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(
                          '${s.eventDate.month}/${s.eventDate.day} ${s.title}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedScheduleId = val;
                      if (val != null) {
                        final matched = availableSchedules
                            .where((s) => s.id == val)
                            .firstOrNull;
                        if (matched != null) {
                          _selectedDate = matched.eventDate;
                          if (_locationController.text.trim().isEmpty) {
                            _locationController.text = matched.destination;
                          }
                          if (_diveCenterController.text.trim().isEmpty) {
                            _diveCenterController.text = matched.diveShop;
                          }
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('5段階評価', style: TextStyle(fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          icon: Icon(
                            starValue <= _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = starValue;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('ダイビング日付'),
                  subtitle: Text(
                    '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: OutlinedButton(
                    onPressed: _pickDate,
                    child: const Text('変更'),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'ポイント名 / スポット *',
                          hintText: '例: 伊豆・大瀬崎（湾内）',
                          prefixIcon: Icon(Icons.place_outlined),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'ポイント名を入力してください';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: OutlinedButton.icon(
                        key: const Key('select_spot_button'),
                        onPressed: () async {
                          final spot = await DiveSpotSelectModal.show(context);
                          if (spot != null) {
                            setState(() {
                              _spotId = spot.id;
                              _latitude = spot.latitude;
                              _longitude = spot.longitude;
                              _locationController.text = spot.name;
                            });
                          }
                        },
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('選択'),
                      ),
                    ),
                  ],
                ),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF0077B6)),
                      const SizedBox(width: 4),
                      Text(
                        '位置情報: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF0077B6),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _spotId = null;
                            _latitude = null;
                            _longitude = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('解除', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _diveCenterController,
                  decoration: const InputDecoration(
                    labelText: '主催センター / ショップ名',
                    hintText: '例: 伊豆ダイバーズステーション',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _divePurpose,
                  decoration: const InputDecoration(
                    labelText: 'ダイビング目的',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: _divePurposes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _divePurpose = val);
                  },
                ),
              ],
            ),

            // 2. 潜水時間・エントリー方式・水域
            _buildSectionCard(
              context: context,
              title: '潜水時間・エントリー・水域',
              icon: Icons.timer_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.login),
                        label: Text('開始: ${_entryTime.format(context)}'),
                        onPressed: _pickEntryTime,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: Text('終了: ${_exitTime.format(context)}'),
                        onPressed: _pickExitTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Chip(
                    avatar: const Icon(Icons.access_time),
                    label: Text(
                      '潜水時間: $_calculatedDurationMinutes 分',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                const Text('エントリー方式', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: _entryMethods.map((method) {
                    return ChoiceChip(
                      label: Text(method),
                      selected: _entryMethod == method,
                      onSelected: (selected) {
                        if (selected) setState(() => _entryMethod = method);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('水域 & 水質', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: [
                    ..._waterAreas.map((area) {
                      return ChoiceChip(
                        label: Text(area),
                        selected: _waterArea == area,
                        onSelected: (selected) {
                          if (selected) setState(() => _waterArea = area);
                        },
                      );
                    }),
                    ..._waterTypes.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: _waterType == type,
                        onSelected: (selected) {
                          if (selected) setState(() => _waterType = type);
                        },
                      );
                    }),
                  ],
                ),
              ],
            ),

            // 3. 水深 & 気圧 (実績と計画)
            _buildSectionCard(
              context: context,
              title: '深度 & 気圧（実績と計画）',
              icon: Icons.speed,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxDepthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '最大水深 (m) *',
                          suffixText: 'm',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return '数値を入力';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _avgDepthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '平均水深 (m) *',
                          suffixText: 'm',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return '数値を入力';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startPressureController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '開始圧 (bar) *',
                          suffixText: 'bar',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return '数値を入力';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endPressureController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '終了圧 (bar) *',
                          suffixText: 'bar',
                        ),
                        validator: (val) {
                          if (val == null || double.tryParse(val) == null) {
                            return '数値を入力';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('計画値 (ダイブプラン)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _plannedDepthController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '計画水深',
                          suffixText: 'm',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _plannedDurationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '計画時間',
                          suffixText: '分',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _plannedReserveController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '計画残圧',
                          suffixText: 'bar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 4. 環境・海況・潮流・潮汐
            _buildSectionCard(
              context: context,
              title: '海況・環境・潮流・潮汐',
              icon: Icons.waves,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _weather,
                        decoration: const InputDecoration(labelText: '天気'),
                        items: _weathers.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _weather = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _airTempController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '気温',
                          suffixText: '℃',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _waterTempMinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '水温 (最小)',
                          suffixText: '℃',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _waterTempMaxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '水温 (最高)',
                          suffixText: '℃',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _visibilityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '透明度',
                          suffixText: 'm',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('潮流タイプ', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: _tideTypes.map((tide) {
                    return ChoiceChip(
                      label: Text(tide),
                      selected: _tideType == tide,
                      onSelected: (selected) {
                        if (selected) setState(() => _tideType = tide);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('水中の流れ', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: _currentLevels.map((lvl) {
                    return ChoiceChip(
                      label: Text(lvl),
                      selected: _underwaterCurrent == lvl,
                      onSelected: (selected) {
                        if (selected) setState(() => _underwaterCurrent = lvl);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('水面の流れ・波浪', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 8,
                  children: _surfaceConditions.map((cond) {
                    return ChoiceChip(
                      label: Text(cond),
                      selected: _surfaceCurrent == cond,
                      onSelected: (selected) {
                        if (selected) setState(() => _surfaceCurrent = cond);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('潮汐時刻 (満潮・干潮 各2回)', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _highTide1Controller,
                        decoration: const InputDecoration(
                          labelText: '満潮 1',
                          hintText: '例: 06:30',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lowTide1Controller,
                        decoration: const InputDecoration(
                          labelText: '干潮 1',
                          hintText: '例: 12:40',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _highTide2Controller,
                        decoration: const InputDecoration(
                          labelText: '満潮 2',
                          hintText: '例: 18:50',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lowTide2Controller,
                        decoration: const InputDecoration(
                          labelText: '干潮 2',
                          hintText: '例: 00:30',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 5. 機材・シリンダー・ウェイト
            _buildSectionCard(
              context: context,
              title: '機材・シリンダー・ウェイト',
              icon: Icons.scuba_diving,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tankVolumeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'シリンダー容量',
                          suffixText: 'L',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _cylinderMaterial,
                        decoration: const InputDecoration(labelText: '材質'),
                        items: _cylinderMaterials.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _cylinderMaterial = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'ウェイト',
                          suffixText: 'kg',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _equipmentController,
                  decoration: const InputDecoration(
                    labelText: '使用機材',
                    hintText: '例: 5mmウェットスーツ, フードベスト, スントD5',
                    prefixIcon: Icon(Icons.backpack_outlined),
                  ),
                ),
              ],
            ),

            // 6. バディ・出会った生物・自由メモ
            _buildSectionCard(
              context: context,
              title: 'バディ・生物・メモ',
              icon: Icons.people_outline,
              children: [
                // バディ名
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buddyInputController,
                        decoration: const InputDecoration(
                          labelText: 'バディ名を追加',
                          hintText: '例: 山田ダイバー',
                          prefixIcon: Icon(Icons.person_add_outlined),
                        ),
                        onSubmitted: (_) => _addBuddy(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _addBuddy,
                      child: const Text('追加'),
                    ),
                  ],
                ),
                if (_buddies.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _buddies.map((buddy) {
                      return Chip(
                        avatar: const Icon(Icons.person, size: 18),
                        label: Text(buddy),
                        onDeleted: () {
                          setState(() {
                            _buddies.remove(buddy);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // 出会った生物
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _marineLifeInputController,
                        decoration: const InputDecoration(
                          labelText: '出会った生物を追加',
                          hintText: '例: アオウミガメ',
                          prefixIcon: Icon(Icons.pets_outlined),
                        ),
                        onSubmitted: (_) => _addMarineLife(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _addMarineLife,
                      child: const Text('追加'),
                    ),
                  ],
                ),
                if (_marineLife.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _marineLife.map((creature) {
                      return Chip(
                        avatar: const Icon(Icons.water, size: 18),
                        label: Text(creature),
                        backgroundColor: Colors.teal.shade50,
                        onDeleted: () {
                          setState(() {
                            _marineLife.remove(creature);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // メモ
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ダイビングメモ・感想',
                    alignLabelWithHint: true,
                    hintText: '透明度良好。流れも弱く快適なダイブ。生物の行動観察など...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('この内容でダイビングログを保存', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
