import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';

/// アカウント新規登録画面
class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authActionControllerProvider.notifier);
    final user = await controller.signUpWithEmail(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
    );

    if (user != null && mounted) {
      // パスワードマネージャーに資格情報の保存を促す
      TextInput.finishAutofillContext();
      // 登録成功時は画面を閉じてメイン側へ遷移
      Navigator.of(context).pop();
    } else if (mounted) {
      final state = ref.read(authActionControllerProvider);
      final errorMsg = state.error?.toString() ?? 'アカウント登録に失敗しました。';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final controller = ref.read(authActionControllerProvider.notifier);
    final user = await controller.signInWithGoogle();

    if (user != null && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final state = ref.read(authActionControllerProvider);
      final errorMsg = state.error?.toString() ?? 'Googleでの登録に失敗しました。';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final actionState = ref.watch(authActionControllerProvider);
    final isLoading = actionState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('新規アカウント登録'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'ダイバーアカウントを作成',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ログブックや機材データをクラウドに保存・同期します',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ユーザー表示名
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.name,
                        ],
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'ダイバー名 / 表示名 (任意)',
                          hintText: '例: 海野 太郎',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // メールアドレス
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.email,
                          AutofillHints.newUsername,
                        ],
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'メールアドレス *',
                          hintText: 'example@scuba.com',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'メールアドレスを入力してください';
                          }
                          if (!value.contains('@')) {
                            return '有効なメールアドレスを入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // パスワード
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.newPassword,
                        ],
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: 'パスワード (6文字以上) *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'パスワードを入力してください';
                          }
                          if (value.length < 6) {
                            return 'パスワードは6文字以上で入力してください';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // パスワード確認
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [
                          AutofillHints.newPassword,
                        ],
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _handleSignUp(),
                        decoration: const InputDecoration(
                          labelText: 'パスワードの確認 *',
                          prefixIcon: Icon(Icons.lock_clock_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '確認のため再度パスワードを入力してください';
                          }
                          if (value != _passwordController.text) {
                            return 'パスワードが一致しません';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 利用規約・プライバシーポリシー案内 (Wrapで横溢れ防止)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '登録することで、',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TermsOfServicePage(),
                                ),
                              ),
                              child: Text(
                                '利用規約',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              ' および ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PrivacyPolicyPage(),
                                ),
                              ),
                              child: Text(
                                'プライバシーポリシー',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              ' に同意したものとみなされます。',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 新規登録ボタン
                      FilledButton(
                        onPressed: isLoading ? null : _handleSignUp,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'アカウントを作成する',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // 区切り線
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'または',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Google SSO 登録ボタン
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _handleGoogleSignUp,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: const Text(
                          'Google で登録',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ログインへの戻りリンク
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            '既にアカウントをお持ちですか？',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text(
                              'ログイン',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
