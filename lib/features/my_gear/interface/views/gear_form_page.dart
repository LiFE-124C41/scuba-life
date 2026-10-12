import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gear_item.dart';
import '../controllers/gear_controller.dart';

/// 機材の新規登録・編集フォーム画面
class GearFormPage extends ConsumerStatefulWidget {
  final GearItem? initialGear;

  const GearFormPage({super.key, this.initialGear});

  @override
  ConsumerState<GearFormPage> createState() => _GearFormPageState();
}

class _GearFormPageState extends ConsumerState<GearFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _serialController;
  late TextEditingController _divesController;
  late TextEditingController _intervalMonthsController;
  late TextEditingController _intervalDivesController;
  late TextEditingController _memoController;

  late GearCategory _category;
  late DateTime _purchaseDate;
  DateTime? _lastOverhaulDate;
  late bool _requiresOverhaul;

  bool get _isEditing => widget.initialGear != null;

  @override
  void initState() {
    super.initState();
    final g = widget.initialGear;

    _nameController = TextEditingController(text: g?.name ?? '');
    _brandController = TextEditingController(text: g?.brand ?? '');
    _modelController = TextEditingController(text: g?.model ?? '');
    _serialController = TextEditingController(text: g?.serialNumber ?? '');
    _divesController = TextEditingController(text: (g?.divesSinceOverhaul ?? 0).toString());
    _intervalMonthsController =
        TextEditingController(text: (g?.overhaulIntervalMonths ?? 12).toString());
    _intervalDivesController = TextEditingController(
      text: g?.overhaulIntervalDives != null ? g!.overhaulIntervalDives.toString() : '100',
    );
    _memoController = TextEditingController(text: g?.memo ?? '');

    _category = g?.category ?? GearCategory.regulator;
    _purchaseDate = g?.purchaseDate ?? DateTime.now();
    _lastOverhaulDate = g?.lastOverhaulDate;
    _requiresOverhaul = g?.requiresOverhaul ?? _category.defaultRequiresOverhaul;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _divesController.dispose();
    _intervalMonthsController.dispose();
    _intervalDivesController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '機材の編集' : '新しい機材を追加'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // カテゴリー選択
              DropdownButtonFormField<GearCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: '機材カテゴリー *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: GearCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                      if (!_isEditing) {
                        _requiresOverhaul = val.defaultRequiresOverhaul;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 機材名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '機材名称 * (例: レギュレーター レジェンド)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '機材名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ブランド & モデル
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'ブランド (例: Apeks)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'モデル・型番',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // シリアル番号
              TextFormField(
                controller: _serialController,
                decoration: const InputDecoration(
                  labelText: 'シリアル番号 / 保証番号',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
              ),
              const SizedBox(height: 16),

              // 購入日ピッカー
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.shopping_cart_outlined),
                title: const Text('購入日'),
                subtitle: Text(
                  '${_purchaseDate.year}年${_purchaseDate.month}月${_purchaseDate.day}日',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _purchaseDate,
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _purchaseDate = picked;
                    });
                  }
                },
              ),

              const Divider(height: 32),

              // オーバーホール設定セクション
              Row(
                children: [
                  const Icon(Icons.build_circle_outlined, color: Color(0xFF0077B6)),
                  const SizedBox(width: 8),
                  const Text(
                    'オーバーホール / メンテナンス管理',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0077B6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('定期オーバーホールの目安を管理する'),
                subtitle: const Text('レギュレーター、BCD、ダイブコンピューター等'),
                value: _requiresOverhaul,
                onChanged: (val) {
                  setState(() {
                    _requiresOverhaul = val;
                  });
                },
              ),

              if (_requiresOverhaul) ...[
                const SizedBox(height: 8),

                // 最終オーバーホール日
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history),
                  title: const Text('最終オーバーホール日'),
                  subtitle: Text(
                    _lastOverhaulDate != null
                        ? '${_lastOverhaulDate!.year}年${_lastOverhaulDate!.month}月${_lastOverhaulDate!.day}日'
                        : '未設定（購入日を基準に計算）',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _lastOverhaulDate != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_lastOverhaulDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: '未設定に戻す',
                          onPressed: () {
                            setState(() {
                              _lastOverhaulDate = null;
                            });
                          },
                        ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _lastOverhaulDate ?? _purchaseDate,
                      firstDate: DateTime(1980),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _lastOverhaulDate = picked;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),

                // OH後ダイブ本数
                TextFormField(
                  controller: _divesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'OH後（または購入後）の潜水本数 (本)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scuba_diving),
                    helperText: '前回のOH以降に潜ったダイブ本数',
                  ),
                  validator: (val) {
                    if (val == null || int.tryParse(val) == null || int.parse(val) < 0) {
                      return '0以上の数値を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 推奨周期（月数 & 本数）
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _intervalMonthsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '推奨周期 (ヶ月)',
                          border: OutlineInputBorder(),
                          helperText: '通常12ヶ月（1年）',
                        ),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
                            return '1以上';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _intervalDivesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '推奨本数 (本)',
                          border: OutlineInputBorder(),
                          helperText: '例: 100本 (空欄可)',
                        ),
                        validator: (val) {
                          if (val != null && val.trim().isNotEmpty) {
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed <= 0) {
                              return '1以上';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(height: 32),

              // メモ
              TextFormField(
                controller: _memoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'メンテナンスメモ・購入店・特記事項',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 28),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(_isEditing ? '更新を保存する' : '機材を登録する'),
                  onPressed: _save,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final id = widget.initialGear?.id ?? 'gear-${DateTime.now().millisecondsSinceEpoch}';
    final dives = int.tryParse(_divesController.text.trim()) ?? 0;
    final months = int.tryParse(_intervalMonthsController.text.trim()) ?? 12;
    final intervalDives = _intervalDivesController.text.trim().isNotEmpty
        ? int.tryParse(_intervalDivesController.text.trim())
        : null;

    final item = GearItem(
      id: id,
      name: _nameController.text.trim(),
      category: _category,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      serialNumber: _serialController.text.trim(),
      purchaseDate: _purchaseDate,
      lastOverhaulDate: _lastOverhaulDate,
      divesSinceOverhaul: dives,
      overhaulIntervalMonths: months,
      overhaulIntervalDives: intervalDives,
      requiresOverhaul: _requiresOverhaul,
      memo: _memoController.text.trim(),
    );

    try {
      await ref.read(gearListNotifierProvider.notifier).saveGear(item);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '機材情報を更新しました' : '新しい機材を登録しました'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    }
  }
}
