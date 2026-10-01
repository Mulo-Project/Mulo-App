import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// 홈 구역의 큰 제목. [onTap]이 있으면 오른쪽에 "›"가 붙어 더 보기로 간다.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontWeight: FontWeight.w800);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              Icon(Icons.chevron_right_rounded, color: p.onSurfaceMuted),
            ],
          ],
        ),
      ),
    );
  }
}

/// 홈 필터 칩: 칩마다 따로 떨어진 알약 (설정의 붙은 라디오 탭이 아님).
/// 고른 칩은 강조 색으로 채우고, 나머지는 테두리만 둔다.
class HomeChip extends StatelessWidget {
  const HomeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: ShapeDecoration(
            color: selected ? p.accent : null,
            shape: StadiumBorder(
              side: BorderSide(color: selected ? p.accent : p.outline),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: selected ? p.onAccent : p.onSurface),
          ),
        ),
      ),
    );
  }
}

/// 칩 한 줄 (왼쪽 정렬, 칩 사이 간격).
class HomeChipRow extends StatelessWidget {
  const HomeChipRow({super.key, required this.chips});

  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.screen,
    child: Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: chips,
    ),
  );
}
