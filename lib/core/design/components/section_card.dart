import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'app_divider.dart';

/// 제목이 붙은 목록 묶음 (설정 목록 등). 카드 면 없이 자식 사이에 옅은 구분선만 둔다.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            // 제목도 줄 글자와 같은 [AppSpacing.md]에서 시작해 왼쪽 선을 맞춘다.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(title!.toUpperCase(), style: text.labelSmall),
          ),
        Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: AppSpacing.md,
                  endIndent: AppSpacing.md,
                  color: p.outline,
                ),
              children[i],
            ],
          ],
        ),
      ],
    );
  }
}

/// 설정 한 줄: 제목 · 설명 · 오른쪽 값/스위치. [below]는 줄 아래에 붙는 컨트롤.
class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.below,
    this.onTap,
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final Widget? below;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleSmall),
                      if (description != null) ...[
                        const SizedBox(height: AppSpacing.hair),
                        Text(description!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
            if (below != null) ...[
              const SizedBox(height: AppSpacing.sm),
              below!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 긴 화면의 구역: 위에 옅은 구분선, 그 아래 작은 제목, 이어서 내용. 카드 면 없이 선과 여백으로만 나눈다.
/// [first]면 맨 위 구역이라 구분선과 위 여백을 생략한다.
class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    this.title,
    required this.children,
    this.first = false,
  });

  final String? title;
  final List<Widget> children;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(top: first ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!first) ...[
            const AppDivider(),
            const SizedBox(height: AppSpacing.md),
          ],
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: text.labelSmall?.copyWith(color: p.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          ...children,
        ],
      ),
    );
  }
}
