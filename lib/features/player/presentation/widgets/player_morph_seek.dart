import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import 'player_seek.dart';

// 모양이 변하는 진행 막대 (player_common에서 나눔).

/// 모양 윤곽을 그리는 길. [extend]는 영역 위로 늘린 높이 (화면 맨 위까지 잇는 용도).
typedef SeekPathBuilder = Path Function(Size size, double extend);

/// 진행 막대가 모양(호 · 틀)을 따라 돌다가, 가사 보기에서는 곧은 막대로 부드럽게 펴진다.
///
/// [straight]가 켜지면 윤곽 위의 점들이 영역 아래쪽의 곧은 막대로 옮겨 가고, 커버는 흐려지고
/// 가사가 나타난다. [reachTop]이면 영역 위로 화면 맨 위까지 늘려서 그린다.
class MorphSeek extends StatefulWidget {
  const MorphSeek({
    super.key,
    required this.progress,
    required this.onSeek,
    this.onSeekStart,
    this.onSeekEnd,
    required this.straight,
    required this.pathOf,
    required this.cover,
    required this.lyrics,
    required this.track,
    required this.fill,
    this.knobRing,
    required this.position,
    required this.total,
    required this.timeAt,
    this.reachTop = false,
  });

  final double progress;
  final ValueChanged<double> onSeek;
  final VoidCallback? onSeekStart;
  final VoidCallback? onSeekEnd;
  final bool straight;
  final SeekPathBuilder pathOf;

  /// 커버 모양 (늘린 영역 전체에 깔린다).
  final Widget Function(Size size, double extend) cover;
  final Widget lyrics;
  final Color track;
  final Color fill;
  final Color? knobRing;
  final bool reachTop;

  /// 현재 · 전체 재생 시간.
  final Duration position;
  final Duration total;

  /// 곡선 모양일 때 현재 · 전체 시간을 양옆에 놓을 가운데 위치 (모양 아래 뚫린 곳).
  final Offset Function(Size size, double extend) timeAt;

  /// 곧은 막대가 놓이는 아래 띠 높이.
  static const band = 64.0;
  static const _samples = 200;

  /// [points] 중 [local]에서 가장 가까운 점의 위치(0 ~ 1)와 거리.
  static (double, double) nearest(List<Offset> points, Offset local) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final d = (points[i] - local).distance;
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return (best / (points.length - 1), bestDist);
  }

  @override
  State<MorphSeek> createState() => _MorphSeekState();
}

class _MorphSeekState extends State<MorphSeek>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
    value: widget.straight ? 1 : 0,
  );
  var _extend = 0.0;
  var _dragging = false;
  var _points = const <Offset>[];

  @override
  void didUpdateWidget(MorphSeek old) {
    super.didUpdateWidget(old);
    if (old.straight != widget.straight) {
      widget.straight ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _measure() {
    if (!widget.reachTop) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final dy = box.localToGlobal(Offset.zero).dy.clamp(0.0, 400.0);
    if ((dy - _extend).abs() > .5) setState(() => _extend = dy);
  }

  List<Offset> _pointsFor(Size size, double t) {
    final metric = widget.pathOf(size, _extend).computeMetrics().first;
    final y = size.height - MorphSeek.band + 24;
    const inset = AppSpacing.lg + TimeThumb.edge + TimeThumb.knobR;
    const n = MorphSeek._samples;
    return [
      for (var i = 0; i <= n; i++)
        Offset.lerp(
          metric.getTangentForOffset(metric.length * i / n)!.position,
          Offset(inset + (size.width - inset * 2) * i / n, y),
          t,
        )!,
    ];
  }

  bool _near(Offset local, double t) {
    final (_, dist) = MorphSeek.nearest(_points, local);
    return dist <= 44 - 16 * t;
  }

  void _endDrag() {
    if (_dragging) widget.onSeekEnd?.call();
    _dragging = false;
  }

  void _seek(Offset local) =>
      widget.onSeek(MorphSeek.nearest(_points, local).$1);

  /// 곡선일 때는 모양 아래 뚫린 곳 양옆에 현재(왼쪽) · 전체(오른쪽) 시간, 곧은 막대일 때는 막대 위 총 시간과
  /// 손잡이 아래 삼각형 + 현재 시간.
  List<Widget> _timeLabels(BuildContext context, Size size, double t) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: p.onSurface.withValues(alpha: .7));
    const w = 72.0;
    final gap = widget.timeAt(size, _extend);
    final v = widget.progress.clamp(0.0, 1.0);
    final head = _points.isEmpty
        ? Offset.zero
        : _points[(v * (_points.length - 1)).round()];
    final lineY = size.height - MorphSeek.band + 24;
    final thumbX = head.dx - TimeThumb.width / 2;
    return [
      if (t < 1) ...[
        Positioned(
          left: gap.dx - 76 - w,
          top: gap.dy - 10,
          width: w,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Text(
                TimeText.clock(widget.position),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
        Positioned(
          left: gap.dx + 76,
          top: gap.dy - 10,
          width: w,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - t,
              child: Text(
                TimeText.clock(widget.total),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ),
      ],
      if (t > 0) ...[
        Positioned(
          right: AppSpacing.lg,
          top: lineY - 24,
          child: Opacity(
            opacity: t,
            child: Text(TimeText.clock(widget.total), style: style),
          ),
        ),
        Positioned(
          left: thumbX,
          top: lineY - TimeThumb.knobR,
          child: Opacity(
            opacity: t,
            child: TimeThumb(
              position: widget.position,
              knobX: head.dx - thumbX,
            ),
          ),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });
    final p = context.palette;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -_extend,
          left: 0,
          right: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, c) {
              final size = c.biggest;
              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = Curves.easeInOutCubic.transform(_c.value);
                  _points = _pointsFor(size, t);
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      _dragging = _near(e.localPosition, t);
                      if (_dragging) {
                        widget.onSeekStart?.call();
                        _seek(e.localPosition);
                      }
                    },
                    onPointerMove: (e) {
                      if (_dragging) _seek(e.localPosition);
                    },
                    onPointerUp: (_) => _endDrag(),
                    onPointerCancel: (_) => _endDrag(),
                    child: Stack(
                      children: [
                        if (t < 1)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Opacity(
                                opacity: 1 - t,
                                child: widget.cover(size, _extend),
                              ),
                            ),
                          ),
                        if (t > 0)
                          Positioned(
                            top: _extend,
                            left: 0,
                            right: 0,
                            bottom: MorphSeek.band,
                            child: IgnorePointer(
                              ignoring: t < 1,
                              child: Opacity(opacity: t, child: widget.lyrics),
                            ),
                          ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _MorphPainter(
                                points: _points,
                                value: widget.progress,
                                t: t,
                                track: Color.lerp(
                                  widget.track,
                                  p.onSurface.withValues(alpha: .2),
                                  t,
                                )!,
                                fill: Color.lerp(widget.fill, p.onSurface, t)!,
                                knobRing: widget.knobRing,
                                shadow: p.scrim.withValues(alpha: .4),
                              ),
                            ),
                          ),
                        ),
                        ..._timeLabels(context, size, t),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MorphPainter extends CustomPainter {
  _MorphPainter({
    required this.points,
    required this.value,
    required this.t,
    required this.track,
    required this.fill,
    required this.knobRing,
    required this.shadow,
  });

  final List<Offset> points;
  final double value;
  final double t;
  final Color track;
  final Color fill;
  final Color? knobRing;
  final Color shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon(points, false), line..color = track);
    final v = value.clamp(0.0, 1.0) * (points.length - 1);
    final whole = v.floor();
    final head = whole >= points.length - 1
        ? points.last
        : Offset.lerp(points[whole], points[whole + 1], v - whole)!;
    if (v > 0) {
      canvas.drawPath(
        Path()..addPolygon([...points.take(whole + 1), head], false),
        line..color = fill,
      );
    }
    final r = 8 - t;
    final ring = knobRing;
    if (ring != null) canvas.drawCircle(head, r + 3, Paint()..color = ring);
    canvas.drawCircle(
      head,
      r,
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawCircle(head, r, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_MorphPainter old) =>
      old.points != points ||
      old.value != value ||
      old.t != t ||
      old.track != track ||
      old.fill != fill;
}
