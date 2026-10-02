import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../bloc/player_style_cubit.dart';
import 'player_common.dart';

/// 설정 "플레이어 테마"의 미리보기: 재생 화면을 단순한 도형으로 그린 그림.
class PlayerStylePreview extends StatelessWidget {
  const PlayerStylePreview({super.key, required this.style});

  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final glow = context.tokens.glow(GlowTone.primary);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.outline),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            glow[1].withValues(alpha: style == PlayerStyle.arc ? .7 : .5),
            glow[2].withValues(alpha: .18),
            p.background,
          ],
          stops: const [0, .55, 1],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: LayoutBuilder(
          builder: (context, c) => Padding(
            padding: EdgeInsets.fromLTRB(
              c.maxWidth * .1,
              c.maxHeight * .05,
              c.maxWidth * .1,
              c.maxHeight * .04,
            ),
            child: switch (style) {
              PlayerStyle.vinyl => _Vinyl(glow: glow),
              PlayerStyle.square => _Square(glow: glow),
              PlayerStyle.fullBleed => _FullBleed(
                glow: glow,
                width: c.maxWidth,
              ),
              PlayerStyle.arc => _Arc(glow: glow),
            },
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.width, {this.height = 6, this.muted = false});

  final double width;
  final double height;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: (muted ? p.onSurfaceMuted : p.onSurface).withValues(
          alpha: muted ? .5 : .85,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.size, {this.solid = false, this.glow = false});

  final double size;
  final bool solid;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glow
            ? p.accent
            : solid
            ? p.onSurface
            : p.onSurface.withValues(alpha: .35),
        boxShadow: glow
            ? [BoxShadow(color: p.accent.withValues(alpha: .6), blurRadius: 14)]
            : null,
      ),
    );
  }
}

const _controls = Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [_Dot(10), _Dot(14), _Dot(30, solid: true), _Dot(14), _Dot(10)],
);

const _titleLines = Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [_Line(70, height: 8), SizedBox(height: 6), _Line(44, muted: true)],
);

class _Vinyl extends StatelessWidget {
  const _Vinyl({required this.glow});

  final List<Color> glow;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        const _Line(34, height: 8, muted: true),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: ThinRingPainter(
                  value: .35,
                  track: p.onSurface.withValues(alpha: .18),
                  fill: p.accent,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: glow,
                      ),
                    ),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: .46,
                        heightFactor: .46,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.scrim.withValues(alpha: .55),
                          ),
                          child: const Center(child: _Line(26, muted: true)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _controls,
      ],
    );
  }
}

class _Square extends StatelessWidget {
  const _Square({required this.glow});

  final List<Color> glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: glow,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(child: _titleLines),
            _Dot(12),
          ],
        ),
        const SizedBox(height: 10),
        const ProgressLine(value: .4, height: 3),
        const SizedBox(height: 8),
        const _Line(36, height: 8, muted: true),
        const SizedBox(height: 14),
        _controls,
      ],
    );
  }
}

class _FullBleed extends StatelessWidget {
  const _FullBleed({required this.glow, required this.width});

  final List<Color> glow;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: OverflowBox(
            maxWidth: width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: glow,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        p.background.withValues(alpha: 0),
                        p.background.withValues(alpha: 0),
                        p.background,
                      ],
                      stops: const [0, .5, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Align(alignment: Alignment.centerLeft, child: _titleLines),
        const SizedBox(height: 12),
        const ProgressLine(value: .4, height: 3),
        const SizedBox(height: 14),
        _controls,
      ],
    );
  }
}

class _Arc extends StatelessWidget {
  const _Arc({required this.glow});

  final List<Color> glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: FractionallySizedBox(
                widthFactor: .7,
                heightFactor: .7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: glow,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const _Line(60, height: 8),
        const SizedBox(height: 6),
        const _Line(38, muted: true),
        const SizedBox(height: 10),
        SizedBox.square(
          dimension: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ProgressRing(
                value: .45,
                size: 84,
                stroke: 3,
                sweep: math.pi * 1.5,
              ),
              const _Dot(26, glow: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_Dot(9), _Dot(9), _Dot(9), _Dot(9), _Dot(9)],
        ),
      ],
    );
  }
}
