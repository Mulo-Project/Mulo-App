import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 제목이 붙은 어두운 둥근 묶음 (설정 목록 등). 자식 사이에 옅은 구분선.
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              0,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Text(title!.toUpperCase(), style: text.labelSmall),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: p.outline.withValues(alpha: .5)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                    color: p.outline.withValues(alpha: .5),
                  ),
                children[i],
              ],
            ],
          ),
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
      borderRadius: BorderRadius.circular(AppRadii.lg),
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
                        const SizedBox(height: 2),
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
