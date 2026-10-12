import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final actionState = ref.watch(authActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定'),
      ),
      body: authState.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('ログインしていません'),
            );
          }

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
                      // プロフィールカード
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
                              // 認証バッジ（Wrapで横溢れ防止）
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                alignment: WrapAlignment.center,
                                children: [
                                  Chip(
                                    avatar: const Icon(
                                      Icons.verified_user_outlined,
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // アカウント詳細情報リスト
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

                      // ログアウトボタン
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
}
