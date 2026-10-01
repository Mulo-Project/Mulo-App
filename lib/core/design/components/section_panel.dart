import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'expand_section.dart';
import 'glass.dart';

/// 홈처럼 한 화면을 몇 개의 구역으로 나눌 때 쓰는 구역 패널.
/// 색 유리 면 위에 [icon] 배지 + [title] 머리줄이 있고, 그 아래에 내용이 온다.
/// [collapsible]이면 머리줄을 눌러 내용을 접고 편다 (기본 펼침).
/// 구역마다 [tone]을 달리 줘서 서로 다른 구역임이 한눈에 보이게 한다.
class SectionPanel extends StatelessWidget {
  const SectionPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.tone = GlowTone.primary,
    this.collapsible = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final GlowTone tone;
  final bool collapsible;

  /// 머리줄 오른쪽 (접기 화살표 앞).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final header = Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: p.accent.withValues(alpha: .18),
          ),
          child: SizedBox.square(
            dimension: 32,
            child: Icon(icon, size: 18, color: p.accent),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(title, style: text.titleMedium)),
        ?trailing,
      ],
    );
    const inset = EdgeInsets.all(AppSpacing.md);

    return Padding(
      padding: AppSpacing.screen,
      child: GlassCard(
        tone: tone,
        glow: false,
        radius: AppRadii.lg,
        padding: EdgeInsets.zero,
        child: collapsible
            ? Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: ExpandSection(
                  padding: inset,
                  header: header,
                  child: child,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(padding: inset, child: header),
                  child,
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
      ),
    );
  }
}
