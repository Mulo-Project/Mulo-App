import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';

/// 화면에 보여 줄 게 없을 때 쓰는 안내의 종류.
enum EmptyKind {
  /// 목록 · 이미지가 없다 (제목 · 설명을 화면이 정한다).
  empty,

  /// 네트워크 연결이 있어야 보이는 화면인데 끊겼다.
  network,

  /// 연결은 됐는데 응답이 너무 오래 걸려 멈췄다 (끊긴 [network]와 구분).
  timeout,

  /// 로그인해야 보이는 화면인데 로그인하지 않았다.
  signIn,
}

/// 비어 있을 때 · 안내할 때의 가운데 정렬 묶음: (아이콘) · 제목 · 설명 · (버튼).
/// 카드 · 상자 없이 가운데에 놓이고, 화면마다 크기 · 간격이 달라지지 않게 빈 화면 · 연결 필요 ·
/// 로그인 필요 안내는 모두 이것으로 그린다. 짧은 영역이면 그 영역의 가운데, 긴 목록 안이면 위아래 여백을 두고 놓인다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required String this.title,
    this.body,
    this.icon,
    this.action,
    this.compact = false,
    this.iconSize,
  }) : kind = EmptyKind.empty,
       onAction = null;

  /// 네트워크 연결이 필요하다는 안내. [onRetry]가 있으면 "다시 시도" 버튼이 붙는다.
  const EmptyState.network({super.key, this.body, VoidCallback? onRetry})
    : kind = EmptyKind.network,
      title = null,
      icon = null,
      action = null,
      compact = false,
      iconSize = null,
      onAction = onRetry;

  /// 응답이 너무 오래 걸려 시간 초과로 멈췄다는 안내. [onRetry]가 있으면 "다시 시도" 버튼이 붙는다.
  const EmptyState.timeout({super.key, this.body, VoidCallback? onRetry})
    : kind = EmptyKind.timeout,
      title = null,
      icon = null,
      action = null,
      compact = false,
      iconSize = null,
      onAction = onRetry;

  /// 로그인이 필요하다는 안내. [onSignIn]이 있으면 "로그인" 버튼이 붙는다.
  const EmptyState.signIn({super.key, this.body, VoidCallback? onSignIn})
    : kind = EmptyKind.signIn,
      title = null,
      icon = null,
      action = null,
      compact = false,
      iconSize = null,
      onAction = onSignIn;

  final EmptyKind kind;
  final String? title;
  final String? body;
  final IconData? icon;

  /// 아래 버튼 (보통 [PillButton] · [PlainButton]).
  final Widget? action;

  /// 아이콘 크기 (비우면 기본 [AppSizes.iconEmpty]). 화면 전체가 비어 아이콘이 주인공일 때만 키운다.
  final double? iconSize;

  /// 목록 · 카드 안에 끼는 한 줄 안내: 위아래 여백을 줄이고 제목도 옅은 본문 글자로 그린다.
  final bool compact;

  /// network · timeout · signIn 종류의 버튼이 누를 때 하는 일.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final l10n = context.l10n;
    final IconData? shownIcon;
    final String shownTitle;
    final String? shownBody;
    final Widget? shownAction;
    switch (kind) {
      case EmptyKind.empty:
        shownIcon = icon;
        shownTitle = title!;
        shownBody = body;
        shownAction = action;
      case EmptyKind.network:
        shownIcon = AppIcons.wifiOff;
        shownTitle = l10n.stateNetworkTitle;
        shownBody = body ?? l10n.stateNetworkBody;
        shownAction = onAction == null
            ? null
            : PillButton(
                label: l10n.actionRetry,
                icon: AppIcons.refresh,
                onPressed: onAction,
              );
      case EmptyKind.timeout:
        shownIcon = AppIcons.hourglassEmpty;
        shownTitle = l10n.stateTimeoutTitle;
        shownBody = body ?? l10n.stateTimeoutBody;
        shownAction = onAction == null
            ? null
            : PillButton(
                label: l10n.actionRetry,
                icon: AppIcons.refresh,
                onPressed: onAction,
              );
      case EmptyKind.signIn:
        shownIcon = AppIcons.lock;
        shownTitle = l10n.stateSignInTitle;
        shownBody = body ?? l10n.stateSignInBody;
        shownAction = onAction == null
            ? null
            : PillButton(
                label: l10n.settingsAccountSignIn,
                icon: AppIcons.person,
                onPressed: onAction,
              );
    }
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: compact ? AppSpacing.sm : AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shownIcon != null) ...[
              Icon(
                shownIcon,
                size: iconSize ?? AppSizes.iconEmpty,
                color: p.accent,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              shownTitle,
              style: compact
                  ? text.bodyMedium?.copyWith(color: p.onSurfaceMuted)
                  : text.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (shownBody != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                shownBody,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (shownAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              shownAction,
            ],
          ],
        ),
      ),
    );
  }
}
