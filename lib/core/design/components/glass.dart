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
  });

  final Widget child;

  /// RoundedRectangleBorder · StadiumBorder · CircleBorder.
  final OutlinedBorder shape;
  final List<Color>? tint;

  /// 바깥으로 은은한 색 빛 (색 유리일 때).
  final bool glow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double blur;

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

    Widget surface = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: ShapeDecoration(gradient: fill, shape: shape),
            child: InkWell(
              onTap: onTap,
              customBorder: shape,
              child: CustomPaint(
                foregroundPainter: _RimPainter(
                  shape: shape,
                  highlight: p.glassHighlight,
                  border: p.glassBorder,
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
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
