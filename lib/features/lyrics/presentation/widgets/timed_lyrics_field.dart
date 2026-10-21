import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import '../../../../core/l10n/l10n.dart';
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

  /// 시간 칸을 누르면 그 줄의 싱크를 다듬는 시트를 연다: 시간 조절 · 묶음에서 떼기 · 여기부터 지우기.
  Future<void> _lineActions(BuildContext context, int i, String line) {
    final l10n = context.l10n;
    // 슬라이더 범위: 앞 줄 시간 ~ 다음 줄 시간 (다음이 없으면 지금부터 10초 뒤). 열 때 정해 끌어도 변하지 않는다.
    final now = times[i]!;
    final range = (
      (i > 0 ? times[i - 1] : null) ?? Duration.zero,
      (i + 1 < times.length ? times[i + 1] : null) ??
          now + const Duration(seconds: 10),
    );
    return showAppSheet<void>(
      context,
      builder: (sheet) => ListenableBuilder(
        listenable: controller,
        builder: (_, _) {
          final at = i < times.length ? times[i] : null;
          if (at == null) return const SizedBox.shrink();
          final prev = i > 0 ? times[i - 1] : null;
          final next = i + 1 < times.length ? times[i + 1] : null;
          final tt = Theme.of(sheet).textTheme;
          final muted = sheet.palette.onSurfaceMuted;
          Widget stop(String title, Duration? t, TextStyle? style) => Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // 이웃 시간을 누르면 그 시간에 딱 붙인다 (같아지면 묶인다).
              onTap: t == null || style == null
                  ? null
                  : () => controller.setTime(i, t),
              child: Column(
                children: [
                  Text(title, style: tt.labelSmall?.copyWith(color: muted)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t == null ? l10n.lyricsTimeNone : lyricTimeLabel(t),
                    style: style ?? tt.bodyMedium?.copyWith(color: muted),
                  ),
                ],
              ),
            ),
          );
          final lower = range.$1, upper = range.$2;
          final accent = sheet.palette.accent;
          // 이웃과 시간이 같아 묶이면 그 이웃 시간도 현재 시간과 같은 색으로 보인다.
          TextStyle? neighborStyle(Duration? t) =>
              tt.bodyMedium?.copyWith(color: t == at ? accent : muted);
          Widget fine(String label, int ms) => PillButton(
            label: label,
            compact: true,
            variant: PillVariant.tonal,
            onPressed: () => controller.adjust(i, Duration(milliseconds: ms)),
          );
          final groupedAbove = prev != null && prev == at;
          final groupedBelow = next != null && next == at;
          return SafeArea(
            child: Padding(
              padding: appSheetPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSheetTitle(
                    lyricTimeLabel(at),
                    subtitle: line.isEmpty ? '♪' : line,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      stop(
                        l10n.lyricsTimePrev,
                        prev,
                        prev == null ? null : neighborStyle(prev),
                      ),
                      stop(
                        l10n.lyricsTimeNow,
                        at,
                        tt.titleMedium?.copyWith(color: accent),
                      ),
                      stop(
                        l10n.lyricsTimeNext,
                        next,
                        next == null ? null : neighborStyle(next),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppSlider(
                    value: at.inMilliseconds
                        .clamp(lower.inMilliseconds, upper.inMilliseconds)
                        .toDouble(),
                    min: lower.inMilliseconds.toDouble(),
                    max: upper.inMilliseconds.toDouble(),
                    semanticLabel: l10n.lyricsTimeNow,
                    onChanged: (v) {
                      // 양 끝 가까이는 이웃 시간에 정확히 붙여 묶이기 쉽게 한다.
                      final ms = v.round();
                      if (ms - lower.inMilliseconds <= 15) {
                        controller.setTime(i, lower);
                      } else if (upper.inMilliseconds - ms <= 15) {
                        controller.setTime(i, upper);
                      } else {
                        controller.setTime(
                          i,
                          Duration(milliseconds: ms ~/ 10 * 10),
                        );
                      }
                    },
                  ),
                  if (groupedAbove || groupedBelow) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      groupedAbove
                          ? l10n.lyricsTimeGroupedAbove
                          : l10n.lyricsTimeGroupedBelow,
                      style: tt.bodySmall?.copyWith(color: accent),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [fine('−0.1s', -100), fine('+0.1s', 100)],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (controller.isGroupedWithAbove(i))
                    MenuRow(
                      icon: AppIcons.restart,
                      label: l10n.lyricsTimeSeparate,
                      onTap: () {
                        controller.separate(i);
                        Navigator.of(sheet).pop();
                      },
                    ),
                  MenuRow(
                    icon: AppIcons.delete,
                    label: l10n.lyricsTimeClearFrom,
                    destructive: true,
                    onTap: () {
                      controller.clearFrom(i);
                      Navigator.of(sheet).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = Theme.of(context).textTheme.bodyMedium!;
    final style = base.copyWith(height: 2.0);
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
            final textWidth = box.maxWidth - gutter;
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
                        _heights = [
                          for (final l in lines)
                            _lineHeight(l, style, scaler, textWidth),
                        ];
                        return SizedBox(
                          width: gutter,
                          child: Column(
                            key: _gutterKey,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < lines.length; i++)
                                SizedBox(
                                  height: _lineHeight(
                                    lines[i],
                                    style,
                                    scaler,
                                    textWidth,
                                  ),
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
                                        ? () =>
                                              _lineActions(context, i, lines[i])
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
                                        style: controller.groupColor(i) == null
                                            ? timeStyle
                                            : timeStyle.copyWith(
                                                color: controller.groupColor(i),
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
    TextScaler scaler,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout(maxWidth: width <= 0 ? 1 : width);
    final h = painter.height;
    painter.dispose();
    return h;
  }
}
