import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';

/// 홈 구역 사이 구분: 위아래 여백 + 얇은 선 (박스 없이 영역만 나눈다).
class HomeDivider extends StatelessWidget {
  const HomeDivider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.lg,
    ),
    child: const AppDivider(),
  );
}

/// 홈 구역의 제목. [onTap]이 있으면 오른쪽에 "›"가 붙어 더 보기로 간다.
class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.title, {super.key, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w700);
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
              Icon(AppIcons.chevronRight, color: p.onSurfaceMuted),
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

/// 접고 펼 수 있는 목록: 소제목 줄을 누르면 [child]가 접힌다 (기본 펼침).
class HomeCollapsible extends StatefulWidget {
  const HomeCollapsible({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  State<HomeCollapsible> createState() => _HomeCollapsibleState();
}

class _HomeCollapsibleState extends State<HomeCollapsible> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(color: p.onSurfaceMuted),
                    ),
                  ),
                  // 아래 곡 줄 오른쪽의 ⋮ 버튼(폭 48)과 아이콘이 같은 세로선에 오도록 같은 폭 안에 가운데 둔다.
                  SizedBox(
                    width: 48,
                    child: Center(
                      child: AnimatedRotation(
                        turns: _open ? .5 : 0,
                        duration: AppMotion.medium,
                        child: Icon(
                          AppIcons.chevronDown,
                          color: p.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: _open ? widget.child : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
