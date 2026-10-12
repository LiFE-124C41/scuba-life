import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_account.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_profile_controller.dart';
import 'widgets/edit_diver_profile_dialog.dart';

/// アカウント設定・プロフィール画面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト確認'),
        content: const Text('アカウントからログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller = ref.read(authActionControllerProvider.notifier);
      await controller.signOut();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退会・アカウント削除の確認'),
        content: const Text(
          'アカウントを削除すると、記録したすべてのダイブログ、マイ機材、トリップ予定データがサーバーから完全に削除され、復元することはできません。\n\n本当に退会しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('アカウントを削除する'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final controller = ref.read(authActionControllerProvider.notifier);
      final success = await controller.deleteAccount();

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アカウントを完全に削除しました。')),
        );
        Navigator.of(context).pop();
      } else {
        final error = ref.read(authActionControllerProvider).error;
        final message = error is Failure ? error.message : 'アカウントの削除に失敗しました。';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(
      BuildContext context, UserAccount user) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => EditDiverProfileDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final actionState = ref.watch(authActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定'),
      ),
      body: authState.when(
        data: (authUser) {
          if (authUser == null) {
            return const Center(
              child: Text('ログインしていません'),
            );
          }

          // Firestore のプロファイルがあればそれを優先、取得中は Auth ユーザーで描画
          final user = profileAsync.asData?.value ?? authUser;

          final displayName = user.displayName?.isNotEmpty == true
              ? user.displayName!
              : 'ダイバー';
          final email = user.email.isNotEmpty ? user.email : '未登録';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. 基本プロフィールカード
                      Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage: user.photoUrl != null
                                    ? NetworkImage(user.photoUrl!)
                                    : null,
                                child: user.photoUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 48,
                                        color: colorScheme.onPrimaryContainer,
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                displayName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              // 認証・ステータスバッジ（Wrapで横溢れ防止）
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  Chip(
                                    avatar: const Icon(
                                      Icons.cloud_done_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('クラウド同期中'),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  if (user.isEmailVerified)
                                    Chip(
                                      avatar: const Icon(
                                        Icons.check_circle_outline,
                                        size: 16,
                                      ),
                                      label: const Text('メール確認済'),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  if (user.certificationOrg != null)
                                    Chip(
                                      avatar: const Icon(
                                        Icons.card_membership_outlined,
                                        size: 16,
                                      ),
                                      label: Text(user.certificationOrg!),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. ダイバー情報・Cカード情報カード
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ヘッダー行 (タイトル + 編集ボタン)
                              Row(
                                children: [
                                  Icon(Icons.badge_outlined, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cカード・ダイバー情報',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showEditProfileDialog(context, user),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('編集'),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              if (user.certificationOrg == null &&
                                  user.certificationLevel == null) ...[
                                // Cカード未登録時のガイダンス
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: colorScheme.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Cカード（ライセンス）情報を登録すると、ログ記録やスキルシートに反映されます。',
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showEditProfileDialog(context, user),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Cカード情報を設定する'),
                                  ),
                                ),
                              ] else ...[
                                // 登録済み情報の表示
                                _buildInfoRow(
                                  context,
                                  icon: Icons.corporate_fare,
                                  label: '指導団体',
                                  value: user.certificationOrg ?? '未設定',
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.military_tech_outlined,
                                  label: '認定ランク',
                                  value: user.certificationLevel ?? '未設定',
                                ),
                                if (user.cCardNumber != null &&
                                    user.cCardNumber!.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    context,
                                    icon: Icons.pin_outlined,
                                    label: 'Cカード番号',
                                    value: user.cCardNumber!,
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  context,
                                  icon: Icons.scuba_diving_outlined,
                                  label: '開始前の経験本数',
                                  value: '${user.totalDivesOffset} 本',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. アカウント詳細情報リスト
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.fingerprint),
                              title: const Text('ユーザー ID (UID)'),
                              subtitle: Text(
                                user.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.calendar_today_outlined),
                              title: const Text('登録日時'),
                              subtitle: Text(
                                user.createdAt != null
                                    ? '${user.createdAt!.year}/${user.createdAt!.month}/${user.createdAt!.day}'
                                    : '記録なし',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. ログアウトボタン
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : () => _showSignOutDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.logout),
                        label: const Text(
                          'ログアウト',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. アカウント完全削除（退会）導線
                      TextButton.icon(
                        onPressed: isLoading ? null : () => _showDeleteAccountDialog(context, ref),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_forever, size: 20),
                        label: const Text(
                          'アカウントを完全に削除（退会）',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('エラー: $err')),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
