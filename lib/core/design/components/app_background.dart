import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 검정 배경 위에 테마 색 빛이 은은하게 번지는 바탕.
///
/// 유리 면(GlassSurface)은 이 빛을 흐리게 비춰서 유리처럼 보인다.
/// 빛 색은 팔레트 글로우에서 오므로 테마(사용자 지정 · 곡 분위기)가 바뀌면 같이 바뀐다.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget glow(Alignment at, Color color, double size, double opacity) =>
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: at,
              child: FractionallySizedBox(
                widthFactor: size,
                heightFactor: size * .6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: opacity),
                        color.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    return ColoredBox(
      color: p.background,
      child: Stack(
        children: [
          glow(const Alignment(-1.1, -1.05), p.glowPrimary[0], 1.5, .42),
          glow(const Alignment(1.2, -.1), p.glowSecondary[0], 1.3, .30),
          glow(const Alignment(-.9, 1.1), p.glowTertiary[1], 1.2, .18),
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }
}
