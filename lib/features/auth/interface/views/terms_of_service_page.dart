import 'package:flutter/material.dart';

/// 利用規約画面
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('利用規約'),
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
                    'Scuba Life 利用規約',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '制定日: 2026年10月1日',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSection(
                    context,
                    title: '第1条（はじめに）',
                    content:
                        '本利用規約（以下「本規約」）は、Scuba Life（以下「本アプリ」）の提供するすべてのサービスにおける利用条件を定めるものです。利用者の皆さま（以下「ユーザー」）には、本規約に同意いただいた上で本アプリをご利用いただきます。',
                  ),
                  _buildSection(
                    context,
                    title: '第2条（アカウント管理）',
                    content:
                        '1. ユーザーは、自己の責任においてアカウントの認証情報（メールアドレス・パスワード・OAuth連携）を適切に管理するものとします。\n'
                        '2. 理由の如何を問わず、アカウントの第三者への譲渡、貸与、売買等は禁止します。\n'
                        '3. ユーザーは、本アプリ内の所定の機能を通じていつでも自身のアカウントおよび登録データを完全に削除（退会）することができます。',
                  ),
                  _buildSection(
                    context,
                    title: '第3条（ダイビングの安全および自己責任に関する重要事項）',
                    content:
                        '1. スクーバダイビングは本来的に危険を伴う海洋アクティビティです。本アプリに記録される潜水ログ、水深計算、SACレート（水面空気消費率）、および海洋気象予報・潮汐データは、あくまで記録および計画支援の補助的参考情報です。\n'
                        '2. 本アプリはダイブコンピューターや認定インストラクター・ガイドの判断を代替するものではありません。実際の潜水計画・減圧管理・残圧管理は、必ず認定ダイブコンピューターおよび有資格者の指示に従い、ユーザー自身の責任において行ってください。\n'
                        '3. 本アプリが提供する海況・気象予報（波高・風速・透明度等）は外部API（Open-Meteo等）に基づく推定値であり、現地の急激な天候変化や潜水適否を保証するものではありません。',
                  ),
                  _buildSection(
                    context,
                    title: '第4条（機材管理・オーバーホール目安に関する免責）',
                    content:
                        '1. マイ機材管理機能におけるオーバーホール（OH）目安日や残り潜水本数は、メーカー推奨値およびユーザー設定に基づく目安計算です。\n'
                        '2. 本アプリの通知やステータス表示に関わらず、潜水器材の点検・整備・保守責任は器材所有者およびダイバー本人にあります。器材の不具合・故障に起因する事故について、本アプリは一切の責任を負いません。',
                  ),
                  _buildSection(
                    context,
                    title: '第5条（禁止事項）',
                    content:
                        'ユーザーは本アプリの利用にあたり、以下の行為を行ってはなりません。\n'
                        '・法令または公序良俗に違反する行為\n'
                        '・本アプリのサーバーやネットワークの機能を破壊・妨害する行為\n'
                        '・他のユーザーまたは第三者の権利を侵害する行為\n'
                        '・リバースエンジニアリング、逆アセンブル等による不正利用',
                  ),
                  _buildSection(
                    context,
                    title: '第6条（サービスの変更・中断・終了）',
                    content:
                        '本アプリは、定期メンテナンスや不測の障害発生時などにおいて、ユーザーへの事前通知なくサービスの一部または全部の提供を一時中断・変更することがあります。',
                  ),
                  _buildSection(
                    context,
                    title: '第7条（規約の改定）',
                    content:
                        '本規約の内容は、必要に応じて改定されることがあります。改定後の規約は、本アプリ内に掲示された時点から効力を生じるものとします。',
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
