import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 유리 면: 뒤를 흐리게 비추는 반투명 면 + 왼쪽 위에 빛이 맺히는 테두리.
///
/// - [tint]가 없으면 무색 유리 (설정 묶음, 입력칸, 탭 바 등).
/// - [tint]가 있으면 그 색 유리 (카드). 보통 [GlassCard]로 쓴다.
/// 색은 모두 팔레트에서 오므로 테마가 바뀌면 같이 바뀐다.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.shape = const RoundedRectangleBorder(
      borderRadius: AppRadii.cardRadius,
    ),
    this.tint,
    this.glow = false,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.blur = AppGlass.blur,
    this.rim = true,
    this.solid = false,
  });

  final Widget child;

  /// RoundedRectangleBorder · StadiumBorder · CircleBorder.
  final OutlinedBorder shape;
  final List<Color>? tint;

  /// 바깥으로 은은한 색 빛 (색 유리일 때).
  final bool glow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// 뒤를 흐리는 정도. 0이면 흐림 없이 반투명 면만 그린다 (목록 줄마다 두는 버튼처럼
  /// 한 화면에 많이 놓일 때는 0으로 두어야 스크롤이 끊기지 않는다).
  final double blur;

  /// 가장자리 빛 테두리를 그릴지. 가로 전체를 쓰는 띠(미니 플레이어)는 끄고 필요한 쪽 선만 직접 긋는다.
  final bool rim;

  /// 흐림(BackdropFilter) 없이 배경색을 깔아 거의 불투명한 유리 모양으로 그린다. 스크롤하는 화면 위에
  /// 늘 떠 있거나 끌려 움직이는 면(미니 플레이어 · 받기 띠 · 플로팅 버튼)은 뒤를 매 프레임 흐리면 버벅이므로 이것을 쓴다.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = this.tint;

    final fill = tint == null
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              p.glassFill.withValues(alpha: p.glassFill.a * 1.6),
              p.glassFill.withValues(alpha: p.glassFill.a * .6),
            ],
          )
        : LinearGradient(
            begin: const Alignment(-.8, -1),
            end: const Alignment(.8, 1),
            colors: [
              for (var i = 0; i < tint.length; i++)
                tint[i].withValues(
                  alpha: p.brightness == Brightness.dark
                      ? AppGlass.tintOpacity[i]
                      : AppGlass.tintOpacityLight[i],
                ),
            ],
          );

    final body = Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(gradient: fill, shape: shape),
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: CustomPaint(
            foregroundPainter: rim
                ? _RimPainter(
                    shape: shape,
                    highlight: p.glassHighlight,
                    border: p.glassBorder,
                  )
                : null,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );

    Widget surface = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      // blur가 0이면 흐릴 것이 없으니 BackdropFilter(= 뒤 화면을 따로 그리는 층)를 만들지 않는다.
      child: solid
          ? DecoratedBox(
              decoration: ShapeDecoration(
                color: p.background.withValues(alpha: .94),
                shape: shape,
              ),
              child: body,
            )
          : blur > 0
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: body,
            )
          : body,
    );

    if (glow && tint != null) {
      surface = DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          shadows: [
            BoxShadow(
              color: tint[1].withValues(alpha: .35),
              blurRadius: 40,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: surface,
      );
    }
    return surface;
  }
}

/// 유리 가장자리: 왼쪽 위는 밝게, 가운데는 옅게, 오른쪽 아래는 살짝 밝게.
/// 안쪽 위쪽에는 얇은 광택 한 줄.
class _RimPainter extends CustomPainter {
  _RimPainter({
    required this.shape,
    required this.highlight,
    required this.border,
  });

  final OutlinedBorder shape;
  final Color highlight;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shape.getInnerPath(rect.deflate(.5));

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          highlight,
          border.withValues(alpha: border.a * .5),
          border,
        ],
        stops: const [0, .55, 1],
      ).createShader(rect);
    canvas.drawPath(path, rim);

    // 위쪽 안쪽 광택.
    canvas.save();
    canvas.clipPath(path);
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.center,
        colors: [
          highlight.withValues(alpha: highlight.a * .22),
          highlight.withValues(alpha: 0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, sheen);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.highlight != highlight || old.border != border || old.shape != shape;
}

/// 색 유리 카드 (레퍼런스의 큰 카드). 색은 [tone]으로만 고른다.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    this.tone = GlowTone.primary,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.glow = true,
    this.radius = AppRadii.card,
    this.onTap,
    required this.child,
  });

  final GlowTone tone;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final double radius;
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GlassSurface(
    tint: context.tokens.glow(tone),
    glow: glow,
    padding: padding,
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    // 라이트에서는 유리를 옅게 칠하므로 글자는 기본 글자색 그대로.
    child: child,
  );
}
