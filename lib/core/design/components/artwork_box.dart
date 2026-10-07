import '../icons/app_icons.dart';

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
    this.icon = AppIcons.musicNote,
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
    final placeholder = DecoratedBox(
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
    );
    final boxWidth = width ?? size;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: boxWidth,
        height: size,
        // 이미지를 못 읽으면(네트워크 썸네일 등) 그라데이션 자리로 돌아간다.
        child: image != null
            ? Image(
                image: _decodedAtBoxSize(
                  image!,
                  boxWidth,
                  size,
                  MediaQuery.devicePixelRatioOf(context),
                ),
                fit: BoxFit.cover,
                // 정렬로 칸의 이미지가 바뀔 때 빈 칸이 번쩍이지 않게 이전 그림을 유지한다.
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => placeholder,
              )
            : placeholder,
      ),
    );
  }
}

/// 칸에 필요한 만큼만 디코딩한다. 유튜브 썸네일 같은 큰 원본(1280x720 등)을 48px 칸에
/// 그대로 풀면 목록을 스크롤할 때마다 디코딩 · 메모리 부담으로 끊긴다.
/// 비율은 유지하고(fit), 짧은 쪽이 칸을 채울 만큼은 남도록 칸의 2배 안으로 줄인다.
ImageProvider _decodedAtBoxSize(
  ImageProvider image,
  double width,
  double height,
  double devicePixelRatio,
) => ResizeImage(
  image,
  width: (width * devicePixelRatio * 2).ceil(),
  height: (height * devicePixelRatio * 2).ceil(),
  policy: ResizeImagePolicy.fit,
);
