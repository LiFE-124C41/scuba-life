import 'package:flutter/material.dart';

/// プライバシーポリシー画面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシーポリシー'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scuba Life プライバシーポリシー',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最終改定日: 2026年10月1日',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSection(
                    context,
                    title: '1. はじめに',
                    content:
                        'Scuba Life（以下「本アプリ」）は、ユーザーの皆さまのプライバシーを尊重し、個人情報の保護に最大限の注意を払っています。本プライバシーポリシーでは、本アプリが収集する情報、その利用目的、および管理方法について説明します。',
                  ),
                  _buildSection(
                    context,
                    title: '2. 収集する情報とその収集方法',
                    content:
                        '本アプリは、サービスの円滑な提供および同期機能のため、以下の情報を収集・保存します。\n\n'
                        '【アカウント認証情報】\n'
                        '・メールアドレス、表示名、プロフィール画像URL（Firebase AuthenticationおよびGoogle等の外部認証連携）\n'
                        '・ユーザー識別子（UID）\n\n'
                        '【ダイバープロファイル情報】\n'
                        '・Cカード認定情報（指導団体、認定ランク、認定番号）\n'
                        '・過去の経験本数（オフセット値）\n\n'
                        '【ダイビング活動データ】\n'
                        '・潜水ログ（日時、水深、潜水時間、残圧、水温、透明度、バディ名、遭遇生物、メモ等）\n'
                        '・ダイビングポイントの緯度・経度情報（地図表示および海況予報API連携のため）\n'
                        '・マイ機材データ（器材名、購入日、OH履歴、シリアル番号等）\n'
                        '・ダイビングスケジュールおよび持ち物チェックリスト',
                  ),
                  _buildSection(
                    context,
                    title: '3. 情報の利用目的',
                    content:
                        '収集した情報は、以下の目的でのみ使用します。\n'
                        '・ユーザー認証およびマルチデバイス間のクラウド同期\n'
                        '・ログブックの記録・分析・ダイバー統計の集計表示\n'
                        '・ダイビング予定日に基づく海洋気象予報の自動取得\n'
                        '・マイ機材のオーバーホール推奨時期の自動算出\n'
                        '・オフライン時の端末内データ保持および電波復帰時の自動同期',
                  ),
                  _buildSection(
                    context,
                    title: '4. 情報の保管と第三者提供',
                    content:
                        '1. ユーザーのデータは、Google Cloud Platform（Cloud Firestore および Firebase Authentication）のセキュアなインフラストラクチャ上に暗号化されて安全に保管されます。\n'
                        '2. セキュリティルールにより、各ユーザーのプライベートデータは本人の認証トークンでのみアクセス可能であり、他のユーザーから閲覧することはできません。\n'
                        '3. 法令に基づく場合を除き、ユーザーの同意なく個人情報を第三者に提供・販売・譲渡することはありません。',
                  ),
                  _buildSection(
                    context,
                    title: '5. データの保持期間とアカウント削除（退会）',
                    content:
                        'ユーザーは、本アプリ内の「プロフィール設定 > アカウントを完全に削除（退会）」より、いつでも自身のアカウントおよび登録データを即座に完全削除することができます。アカウント削除が実行された場合、Firestore 上のすべてのサブコレクション（ログブック、機材、予定、お気に入りスポット）およびユーザードキュメントは物理的に一括破棄され、復元することはできません。',
                  ),
                  _buildSection(
                    context,
                    title: '6. お問い合わせ・ポリシーの改定',
                    content:
                        '本ポリシーは、法令の変更やサービス内容の拡充に伴い改定されることがあります。重要な変更がある場合は、アプリ内にて告知いたします。',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
