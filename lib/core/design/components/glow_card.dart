import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 둥근 그라데이션 카드 + 은은한 바깥 광.
///
/// 색은 [tone]으로만 고른다. 실제 색은 현재 팔레트가 정하므로
/// 사용자 지정 · 곡 분위기 테마에서도 그대로 동작한다.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    this.tone = GlowTone.primary,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.glow = true,
    this.onTap,
    required this.child,
  });

  final GlowTone tone;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.glow(tone);
    final p = context.palette;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardRadius,
        boxShadow: glow
            ? [
                BoxShadow(
                  color: colors[1].withValues(alpha: .35),
                  blurRadius: 48,
                  spreadRadius: -8,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.cardRadius,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              // 왼쪽 위에서 퍼지는 빛 + 아래로 가라앉는 어둠.
              gradient: RadialGradient(
                center: const Alignment(-.7, -.8),
                radius: 1.5,
                colors: colors,
                stops: const [0, .45, 1],
              ),
              border: Border.all(color: p.outline.withValues(alpha: .15)),
              borderRadius: AppRadii.cardRadius,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.cardRadius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
