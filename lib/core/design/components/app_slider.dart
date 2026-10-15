import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 가는 막대 슬라이더 (이퀄라이저 대역 · 저음 강화). 가로 또는 세로.
/// 트랙은 옅은 면, 채움은 강조 색이고 손잡이는 작은 동그라미다. [value]는 [min]~[max].
class AppSlider extends StatelessWidget {
  const AppSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0,
    this.max = 1,
    this.vertical = false,
    this.centered = false,
    this.marks = const [],
    this.thumbAlpha = 1,
    this.semanticLabel,
  });

  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;

  /// 손을 뗄 때 (저장 시점).
  final VoidCallback? onChangeEnd;
  final bool vertical;

  /// true면 가운데(0)에서부터 채운다 (±범위 슬라이더).
  final bool centered;

  /// 트랙 위에 작게 찍는 표시 위치 ([min]~[max] 값). 가로 슬라이더만.
  final List<double> marks;

  /// 손잡이 불투명도 (0~1). 아래 표시가 비쳐 보이게 할 때 낮춘다.
  final double thumbAlpha;
  final String? semanticLabel;

  static const double _track = 4;
  static const double _knob = 16;

  double _fraction(double v) =>
      max == min ? 0 : ((v - min) / (max - min)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onChanged != null;

    return Semantics(
      slider: true,
      label: semanticLabel,
      value: value.toStringAsFixed(1),
      enabled: enabled,
      child: LayoutBuilder(
        builder: (context, box) {
          final length = vertical ? box.maxHeight : box.maxWidth;
          final usable = length - _knob;

          void update(Offset local) {
            if (!enabled || usable <= 0) return;
            final pos = vertical ? local.dy : local.dx;
            var f = ((pos - _knob / 2) / usable).clamp(0.0, 1.0);
            if (vertical) f = 1 - f;
            onChanged!(min + (max - min) * f);
          }

          final f = _fraction(value);
          final zero = centered ? _fraction(0) : 0.0;
          final from = f < zero ? f : zero;
          final to = f < zero ? zero : f;

          // 길이 방향 위치(0이 시작점)를 Positioned로 옮긴다.
          Widget along(double start, double len, Widget child) => vertical
              ? Positioned(
                  bottom: _knob / 2 + usable * start,
                  height: len,
                  left: 0,
                  right: 0,
                  child: Center(child: child),
                )
              : Positioned(
                  left: _knob / 2 + usable * start,
                  width: len,
                  top: 0,
                  bottom: 0,
                  child: Center(child: child),
                );

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => update(d.localPosition),
            onTapUp: (_) => onChangeEnd?.call(),
            onHorizontalDragStart: vertical
                ? null
                : (d) => update(d.localPosition),
            onHorizontalDragUpdate: vertical
                ? null
                : (d) => update(d.localPosition),
            onHorizontalDragEnd: vertical ? null : (_) => onChangeEnd?.call(),
            onVerticalDragStart: vertical
                ? (d) => update(d.localPosition)
                : null,
            onVerticalDragUpdate: vertical
                ? (d) => update(d.localPosition)
                : null,
            onVerticalDragEnd: vertical ? (_) => onChangeEnd?.call() : null,
            child: Opacity(
              opacity: enabled ? 1 : .4,
              child: SizedBox(
                width: vertical ? _knob + 8 : null,
                height: vertical ? null : _knob + 8,
                child: Stack(
                  children: [
                    along(
                      0,
                      usable,
                      Container(
                        width: vertical ? _track : null,
                        height: vertical ? null : _track,
                        decoration: ShapeDecoration(
                          color: p.outline,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    along(
                      from,
                      usable * (to - from),
                      Container(
                        width: vertical ? _track : null,
                        height: vertical ? null : _track,
                        decoration: ShapeDecoration(
                          color: p.accent,
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    if (!vertical)
                      for (final m in marks)
                        along(
                          _fraction(m),
                          0,
                          OverflowBox(
                            maxWidth: 3,
                            maxHeight: _track + 10,
                            child: Container(
                              width: 3,
                              height: _track + 10,
                              decoration: ShapeDecoration(
                                color: p.accent,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                    along(
                      f,
                      0,
                      OverflowBox(
                        maxWidth: _knob,
                        maxHeight: _knob,
                        child: Container(
                          width: _knob,
                          height: _knob,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent.withValues(alpha: thumbAlpha),
                            border: Border.all(
                              color: p.background.withValues(alpha: thumbAlpha),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
