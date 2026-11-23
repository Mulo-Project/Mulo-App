import 'package:flutter/material.dart';

/// 한 줄 글자. 칸보다 길면 멈춤 없이 옆으로 계속 이어져 흐르고(끝이 지나면 처음이 바로 이어 나온다),
/// 들어가면 그냥 [Text]다.
///
/// [scroll]이 false이거나 기기가 동작 줄이기를 켰으면 넘칠 때도 `…`로 줄인다 (목록처럼 한꺼번에 움직이면 산만한 곳).
class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.scroll = true,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool scroll;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  static const _gap = 40.0;
  static const _pixelsPerSecond = 36.0;
  static const _fade = 16.0;

  late final AnimationController _controller = AnimationController(vsync: this);
  double _overflow = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(double overflow, double textWidth) {
    if (overflow == _overflow) return;
    _overflow = overflow;
    if (overflow <= 0) {
      _controller.reset();
      return;
    }
    // 글자 한 번 + 틈만큼 가면 뒤따르는 같은 글자가 제자리에 와서 끊김 없이 이어진다.
    final travel = textWidth + _gap;
    _controller
      ..duration = Duration(
        milliseconds: (travel / _pixelsPerSecond * 1000).round(),
      )
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    final plain = Text(
      widget.text,
      style: widget.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.textAlign,
    );
    // 접근성 "동작 줄이기"가 켜져 있으면 흘리지 않고 …로 줄인다.
    if (!widget.scroll || MediaQuery.disableAnimationsOf(context)) return plain;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final textWidth = painter.width;
        final textHeight = painter.height;
        painter.dispose();
        final overflow = textWidth - constraints.maxWidth;
        if (!constraints.hasBoundedWidth || overflow <= 0.5) {
          if (_overflow != 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _run(0, 0);
            });
          }
          return plain;
        }
        if (_overflow != overflow) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _run(overflow, textWidth);
          });
        }
        final travel = textWidth + _gap;
        final edge = (_fade / constraints.maxWidth).clamp(0.0, .3);
        final label = Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
        );
        return ShaderMask(
          // 양쪽 끝을 살짝 흐리게 해서 글자가 들어오고 나가는 자리가 부드럽게 보인다.
          shaderCallback: (rect) => LinearGradient(
            colors: const [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent,
            ],
            stops: [0, edge, 1 - edge, 1],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: textHeight,
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final dx = _controller.value * travel;
                  return OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    minWidth: 0,
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-dx, 0),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    label,
                    const SizedBox(width: _gap),
                    label,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
