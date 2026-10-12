import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/diver_certification.dart';
import '../../../domain/entities/user_account.dart';
import '../../controllers/user_profile_controller.dart';

/// ダイバー情報（Cカード・表示名・オフセット本数）編集ダイアログ
class EditDiverProfileDialog extends ConsumerStatefulWidget {
  final UserAccount user;

  const EditDiverProfileDialog({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditDiverProfileDialog> createState() =>
      _EditDiverProfileDialogState();
}

class _EditDiverProfileDialogState
    extends ConsumerState<EditDiverProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _cCardNumberController;
  late final TextEditingController _totalDivesOffsetController;
  late final TextEditingController _customOrgController;

  String? _selectedOrg;
  String? _selectedLevel;
  bool _isCustomOrg = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.user.displayName ?? '');
    _cCardNumberController =
        TextEditingController(text: widget.user.cCardNumber ?? '');
    _totalDivesOffsetController = TextEditingController(
      text: widget.user.totalDivesOffset > 0
          ? widget.user.totalDivesOffset.toString()
          : '',
    );

    // 指導団体の初期値
    final currentOrg = widget.user.certificationOrg;
    if (currentOrg != null && currentOrg.isNotEmpty) {
      if (DiverCertification.organizations.contains(currentOrg)) {
        _selectedOrg = currentOrg;
      } else {
        _selectedOrg = 'その他';
        _isCustomOrg = true;
        _customOrgController = TextEditingController(text: currentOrg);
      }
    } else {
      _selectedOrg = 'PADI';
    }
    if (!_isCustomOrg) {
      _customOrgController = TextEditingController();
    }

    // 認定ランクの初期値
    final currentLevel = widget.user.certificationLevel;
    if (currentLevel != null && currentLevel.isNotEmpty) {
      if (DiverCertification.levels.contains(currentLevel)) {
        _selectedLevel = currentLevel;
      } else {
        _selectedLevel = DiverCertification.levels.first;
      }
    } else {
      _selectedLevel = DiverCertification.levels.first;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _cCardNumberController.dispose();
    _totalDivesOffsetController.dispose();
    _customOrgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final org = _selectedOrg == 'その他' && _customOrgController.text.trim().isNotEmpty
        ? _customOrgController.text.trim()
        : _selectedOrg;

    final offsetText = _totalDivesOffsetController.text.trim();
    final offset = offsetText.isNotEmpty ? int.tryParse(offsetText) ?? 0 : 0;

    final notifier = ref.read(userProfileControllerProvider.notifier);
    final success = await notifier.updateProfile(
      userId: widget.user.id,
      displayName: _displayNameController.text.trim(),
      certificationOrg: org,
      certificationLevel: _selectedLevel,
      cCardNumber: _cCardNumberController.text.trim(),
      totalDivesOffset: offset,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ダイバー情報を更新しました'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('更新に失敗しました。もう一度お試しください。'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(userProfileControllerProvider);
    final isLoading = state.isLoading;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.badge_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ダイバー情報・Cカード',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 表示名（ニックネーム）
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'ダイバー名 / 表示名',
                    hintText: '例: 海野 太郎',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '表示名を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 指導団体 (Dropdown)
                DropdownButtonFormField<String>(
                  initialValue: _selectedOrg,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Cカード発行団体 (指導団体)',
                    prefixIcon: Icon(Icons.corporate_fare),
                    border: OutlineInputBorder(),
                  ),
                  items: DiverCertification.organizations.map((org) {
                    return DropdownMenuItem<String>(
                      value: org,
                      child: Text(org),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) {
                          setState(() {
                            _selectedOrg = val;
                            _isCustomOrg = val == 'その他';
                          });
                        },
                ),
                if (_isCustomOrg) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customOrgController,
                    decoration: const InputDecoration(
                      labelText: '団体名を入力',
                      hintText: '例: BSAC, STARS 等',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (_isCustomOrg &&
                          (value == null || value.trim().isEmpty)) {
                        return '指導団体名を入力してください';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // 認定ランク (Dropdown)
                DropdownButtonFormField<String>(
                  initialValue: _selectedLevel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '認定ランク (ライセンス)',
                    prefixIcon: Icon(Icons.military_tech_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: DiverCertification.levels.map((lvl) {
                    return DropdownMenuItem<String>(
                      value: lvl,
                      child: Text(
                        lvl,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) {
                          setState(() {
                            _selectedLevel = val;
                          });
                        },
                ),
                const SizedBox(height: 16),

                // Cカード認定番号
                TextFormField(
                  controller: _cCardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Cカード番号 (任意)',
                    hintText: '例: 1234567890',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // アプリ導入前の潜水本数（本数オフセット）
                TextFormField(
                  controller: _totalDivesOffsetController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '開始前の経験潜水本数 (任意)',
                    hintText: '例: 25',
                    prefixIcon: Icon(Icons.scuba_diving_outlined),
                    suffixText: '本',
                    border: OutlineInputBorder(),
                    helperText: '※本アプリ利用前の総本数。累計ログ本数に加算されます',
                    helperMaxLines: 2,
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        FilledButton.icon(
          onPressed: isLoading ? null : _submit,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('保存'),
        ),
      ],
    );
  }
}
