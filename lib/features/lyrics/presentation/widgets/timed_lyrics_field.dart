import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import 'lyric_time_sheet.dart';
import 'timed_lyrics_controller.dart';

/// 가사 글 한 덩어리를 고치는 칸. 오른쪽은 이어서 복사 · 붙여넣기 할 수 있는 한 개의 입력칸이고,
/// 왼쪽에는 줄 번호에 맞는 싱크 시간을 줄마다 따로 보여 준다 (시간은 고칠 수 없다).
/// 줄 간격을 넓혀 시간과 글이 한 줄씩 맞아 보이게 한다. 긴 줄이 접혀도 시간은 그 줄 맨 위에 선다.
class TimedLyricsField extends StatefulWidget {
  const TimedLyricsField({
    super.key,
    required this.controller,
    this.showTimes = true,
    this.hint,
  });

  /// 글과 줄마다의 시간을 들고 있는 컨트롤러. 시간이 하나도 없으면 시간 칸 없이 글만 보인다.
  final TimedLyricsController controller;

  /// 시간 칸을 보이는가. 싱크가 없는 일반 글 가사는 글만 보인다.
  final bool showTimes;
  final String? hint;

  @override
  State<TimedLyricsField> createState() => _TimedLyricsFieldState();
}

class _TimedLyricsFieldState extends State<TimedLyricsField> {
  TimedLyricsController get controller => widget.controller;
  bool get showTimes => widget.showTimes;
  String? get hint => widget.hint;
  List<Duration?> get times => controller.times;

  /// 시간 칸을 꾹 눌러 끌어 묶을 범위 (기준 줄, 지금 손가락이 있는 줄).
  int? _dragFrom;
  int? _dragTo;
  var _heights = <double>[];
  (String, double, TextScaler)? _measuredFor;
  final _gutterKey = GlobalKey();

  int _rowAt(Offset global) {
    final box = _gutterKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _heights.isEmpty) return _dragTo ?? 0;
    final dy = box.globalToLocal(global).dy;
    var top = 0.0;
    for (var i = 0; i < _heights.length; i++) {
      top += _heights[i];
      if (dy < top) return i;
    }
    return _heights.length - 1;
  }

  bool _inDrag(int i) =>
      _dragFrom != null &&
      _dragTo != null &&
      i >= (_dragFrom! < _dragTo! ? _dragFrom! : _dragTo!) &&
      i <= (_dragFrom! > _dragTo! ? _dragFrom! : _dragTo!);

  void _dragEnd() {
    final a = _dragFrom, b = _dragTo;
    setState(() {
      _dragFrom = null;
      _dragTo = null;
    });
    if (a != null && b != null) controller.groupRange(a, b);
  }

  /// 입력칸은 글자를 줄 끝에서 커서 자리(간격 1 + 커서 폭 2)만큼 먼저 접는다. 시간 칸이 줄 높이를 잴 때도
  /// 같은 폭으로 접어야 줄 수가 같아 시간이 어긋나지 않는다.
  static const _caretMargin = 3.0;

  static const _gutter = 68.0;
  static const _pad = AppSpacing.md;

  /// [i]번 줄이 앞 줄과 시간이 같아 한 묶음인가 (싱크 화면에서 묶은 줄).
  bool _grouped(int i) =>
      i > 0 && i < times.length && times[i] != null && times[i] == times[i - 1];

  /// 시간 칸 글자: 묶음의 둘째 줄부터는 시간을 되풀이하지 않고 이어지는 선으로 보인다.
  String _label(int i) {
    if (i >= times.length || times[i] == null) return '';
    return _grouped(i) ? '│' : lyricTimeLabel(times[i]!);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = Theme.of(context).textTheme.bodyMedium!;
    final style = base.copyWith(height: 2.0);
    // 줄 높이를 글꼴(한글 · 이모지 대체 글꼴 등)과 상관없이 늘 같게 고정해 시간 칸과 글이 어긋나지 않게 한다.
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);
    final timeStyle = style.copyWith(color: p.onSurfaceMuted);
    final scaler = MediaQuery.textScalerOf(context);
    final hi = p.accent.withValues(alpha: .18);
    controller.groupPalette = [p.accent];

    // 테두리 없이 아주 옅은 바탕만 깔아 가사 보기처럼 조용하게, 그래도 입력칸임은 알아보게 한다.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surfaceHigh.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _pad,
          vertical: AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final gutter = showTimes ? _gutter : 0.0;
            final textWidth = box.maxWidth - gutter - _caretMargin;
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showTimes)
                    ListenableBuilder(
                      listenable: controller,
                      builder: (_, _) {
                        final lines = controller.text.split('\n');
                        // 줄 높이는 글 · 폭 · 글자 배율이 바뀔 때만 다시 잰다 (시간만 끌 때는 그대로).
                        final key = (controller.text, textWidth, scaler);
                        if (_measuredFor != key) {
                          _measuredFor = key;
                          _heights = [
                            for (final l in lines)
                              _lineHeight(l, style, strut, scaler, textWidth),
                          ];
                        }
                        final colors = controller.groupColors();
                        return SizedBox(
                          width: gutter,
                          child: Column(
                            key: _gutterKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < lines.length; i++)
                                SizedBox(
                                  height: _heights[i],
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    // 시간 칸을 꾹 눌러 끌면 그 줄을 기준으로 줄을 묶는다.
                                    onLongPressStart:
                                        i < times.length && times[i] != null
                                        ? (_) => setState(() {
                                            _dragFrom = i;
                                            _dragTo = i;
                                          })
                                        : null,
                                    onLongPressMoveUpdate: (d) {
                                      if (_dragFrom == null) return;
                                      final to = _rowAt(d.globalPosition);
                                      if (to != _dragTo) {
                                        setState(() => _dragTo = to);
                                      }
                                    },
                                    onLongPressEnd: (_) => _dragEnd(),
                                    onLongPressCancel: () => setState(() {
                                      _dragFrom = null;
                                      _dragTo = null;
                                    }),
                                    onTap: i < times.length && times[i] != null
                                        ? () => showLyricTimeSheet(
                                            context,
                                            controller: controller,
                                            index: i,
                                            line: lines[i],
                                          )
                                        : null,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: _inDrag(i) ? hi : null,
                                        borderRadius: BorderRadius.circular(
                                          AppRadii.sm,
                                        ),
                                      ),
                                      child: Text(
                                        _label(i),
                                        style: colors[i] == null
                                            ? timeStyle
                                            : timeStyle.copyWith(
                                                color: colors[i],
                                              ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: style,
                      strutStyle: strut,
                      minLines: 12,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: style.copyWith(color: p.onSurfaceMuted),
                        isCollapsed: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 한 줄(접히면 여러 줄)이 입력칸에서 차지하는 높이.
  static double _lineHeight(
    String line,
    TextStyle style,
    StrutStyle strut,
    TextScaler scaler,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: strut,
    )..layout(maxWidth: width <= 0 ? 1 : width);
    final h = painter.height;
    painter.dispose();
    return h;
  }
}
