import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import 'player_common.dart';

// 플레이어 진행 막대 · 시간 표시 (player_common에서 나눔).

/// 기본 원형 손잡이 + 아래로 이어지는 둥근 삼각형 + 현재 재생 시간 상자를 한 덩어리로 그린 손잡이.
/// 총 재생 시간은 막대 위 오른쪽.
class PlayerSeekBar extends StatelessWidget {
  const PlayerSeekBar({
    super.key,
    required this.progress,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.position,
    required this.total,
    this.loopStart,
    this.loopEnd,
  });

  final double progress;
  final ValueChanged<double> onSeek;

  /// 끌기(또는 누르기) 시작 · 끝. 끝날 때 한 번만 실제로 옮기는 데 쓴다.
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final Duration position;
  final Duration total;

  /// 구간 반복의 시작 · 끝. 막대에 그 구간을 강조해 보여 준다 (끝이 없으면 시작 표시만).
  final Duration? loopStart;
  final Duration? loopEnd;

  static const _knob = 14.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: p.onSurface.withValues(alpha: .7));
    return LayoutBuilder(
      builder: (context, c) {
        final room = c.maxWidth - TimeThumb.edge * 2 - _knob;
        void seek(Offset local) => onSeek((local.dx - _knob / 2) / room);
        final v = progress.clamp(0.0, 1.0);
        final knobX = room * v + _knob / 2;
        final ms = total.inMilliseconds;
        double? at(Duration? d) => d == null || ms == 0
            ? null
            : room * (d.inMilliseconds / ms) + _knob / 2;
        final loopA = at(loopStart);
        final loopB = at(loopEnd);
        final thumbX = knobX - TimeThumb.width / 2;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: TimeThumb.edge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(TimeText.clock(total), style: style),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  onSeekStart?.call();
                  seek(d.localPosition);
                },
                onTapUp: (_) => onSeekEnd?.call(),
                onTapCancel: () => onSeekEnd?.call(),
                onHorizontalDragStart: (_) => onSeekStart?.call(),
                onHorizontalDragUpdate: (d) => seek(d.localPosition),
                onHorizontalDragEnd: (_) => onSeekEnd?.call(),
                onHorizontalDragCancel: () => onSeekEnd?.call(),
                child: SizedBox(
                  height: 28,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 4,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: p.onSurface.withValues(alpha: .2),
                        ),
                      ),
                      Container(
                        height: 4,
                        width: knobX,
                        decoration: ShapeDecoration(
                          shape: const StadiumBorder(),
                          color: p.onSurface,
                        ),
                      ),
                      if (loopA != null)
                        Positioned(
                          left: loopA,
                          width: ((loopB ?? loopA) - loopA).clamp(
                            3.0,
                            c.maxWidth,
                          ),
                          child: Container(
                            height: 8,
                            decoration: ShapeDecoration(
                              shape: const StadiumBorder(),
                              color: p.accent.withValues(alpha: .85),
                            ),
                          ),
                        ),
                      Positioned(
                        left: thumbX,
                        top: 14 - TimeThumb.knobR,
                        child: TimeThumb(
                          position: position,
                          knobX: knobX - thumbX,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TimeThumb.height - 21),
            ],
          ),
        );
      },
    );
  }
}

/// 진행 막대 손잡이: 원형 손잡이 아래로 둥근 삼각형이 이어지고, 그 아래 현재 재생 시간 상자.
/// 손잡이 원의 가운데가 가로 [knobX] (왼쪽 위 모서리 기준), 세로 [knobR]에 놓인다.
class TimeThumb extends StatelessWidget {
  const TimeThumb({super.key, required this.position, required this.knobX});

  final Duration position;
  final double knobX;

  static const width = 52.0;
  static const height = 40.0;
  static const knobR = 7.0;

  /// 손잡이가 막대 끝에 가도 상자가 밀리지 않도록 막대 양끝에 두는 여백.
  static const edge = width / 2 - knobR;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ThumbPainter(
                  color: p.onSurface,
                  shadow: p.scrim.withValues(alpha: .3),
                  knobX: knobX,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 22,
              child: Center(
                child: Text(
                  TimeText.clock(position),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: p.background,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter({
    required this.color,
    required this.shadow,
    required this.knobX,
  });

  final Color color;
  final Color shadow;
  final double knobX;

  @override
  void paint(Canvas canvas, Size size) {
    const r = TimeThumb.knobR;
    final x = knobX;
    final l = (x - 7).clamp(2.0, size.width);
    final rt = (x + 7).clamp(0.0, size.width - 2);
    final body = RRect.fromLTRBR(
      0,
      size.height - 22,
      size.width,
      size.height,
      const Radius.circular(11),
    );
    final base = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, r), radius: r))
      ..addRRect(body);
    final neck = Path()
      ..moveTo(x, r + 2)
      ..lineTo(rt, body.top + 1)
      ..lineTo(l, body.top + 1)
      ..close();
    final all = Path.combine(PathOperation.union, base, neck);
    canvas.drawPath(
      all,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(all, Paint()..color = color);
    // 삼각형 모서리를 둥글게.
    canvas.drawPath(
      neck,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ThumbPainter old) =>
      old.color != color || old.knobX != knobX || old.shadow != shadow;
}

/// "02:15 / 44:39" 글자.
class TimeText extends StatelessWidget {
  const TimeText({super.key, required this.data});

  final PlayerLayoutData data;

  static String clock(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$sec' : '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PositionBuilder(
      builder: (context, state) => Text.rich(
        TextSpan(
          children: [
            TextSpan(text: clock(state.position)),
            TextSpan(
              text: ' / ${clock(data.track.duration)}',
              style: TextStyle(color: p.onSurface.withValues(alpha: .6)),
            ),
          ],
        ),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}
