import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../glow_color.dart';

/// 목록에서 항목마다 커버 톤을 고정으로 다르게 고른다 (같은 키 = 같은 톤).
GlowTone toneFor(String key) =>
    GlowTone.values[key.codeUnits.fold(0, (a, b) => a + b) %
        GlowTone.values.length];

/// 커버 아트 자리. 이미지가 없으면 [tone] 글로우 그라데이션 + 음표.
///
/// 목록에서 곡마다 다른 톤을 주려면 [GlowTone.values]를 곡 id로 고른다.
class ArtworkBox extends StatelessWidget {
  const ArtworkBox({
    super.key,
    this.image,
    this.size = 48,
    this.width,
    this.radius = 12,
    this.tone = GlowTone.primary,
    this.color,
    this.icon = Icons.music_note_rounded,
  });

  final ImageProvider? image;
  final double size;

  /// 가로가 다르면 (세로 [size]) 직사각형 커버. 없으면 정사각형.
  final double? width;
  final double radius;
  final GlowTone tone;

  /// 사용자가 고른 색. 있으면 [tone] 대신 이 색으로 그린다.
  final Color? color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final glow = color != null
        ? glowFromColor(color!)
        : context.tokens.glow(tone);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width ?? size,
        height: size,
        child: image != null
            ? Image(image: image!, fit: BoxFit.cover)
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-.6, -.7),
                    radius: 1.4,
                    colors: glow,
                    stops: const [0, .5, 1],
                  ),
                ),
                child: Icon(
                  icon,
                  color: context.palette.onGlow.withValues(alpha: .9),
                  size: size * .4,
                ),
              ),
      ),
    );
  }
}
