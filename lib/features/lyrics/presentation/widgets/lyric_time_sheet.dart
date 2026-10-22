import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import 'timed_lyrics_controller.dart';

/// 가사 줄의 시간 칸을 누르면 뜨는 시트 (바꾼 시간은 시트가 닫힐 때 한 번에 적용한다): 큰 시간 숫자 아래에 이전~다음 범위 슬라이더,
/// 그 밑에 [−] 단위 [+] 한 줄, 맨 아래에 묶음에서 떼기 · 싱크 지우기.
Future<void> showLyricTimeSheet(
  BuildContext context, {
  required TimedLyricsController controller,
  required int index,
  required String line,
}) {
  final at = controller.times[index];
  if (at == null) return Future.value();
  // 슬라이더 범위는 열 때 정해 끌어도 변하지 않는다 (다음 줄이 없으면 지금부터 10초 뒤까지).
  final lower =
      (index > 0 ? controller.times[index - 1] : null) ?? Duration.zero;
  final next = index + 1 < controller.times.length
      ? controller.times[index + 1]
      : null;
  final upper = next ?? at + const Duration(seconds: 10);
  // 시트 안에서는 이 값만 바뀐다. 가사 칸은 시트가 닫힐 때 한 번만 갱신한다 (끄는 동안 렉이 없게).
  final draft = ValueNotifier<Duration>(at);
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (_) => _LyricTimeSheet(
      draft: draft,
      controller: controller,
      index: index,
      line: line,
      lower: lower,
      upper: upper,
    ),
  ).whenComplete(() {
    controller.setTime(index, draft.value);
    draft.dispose();
  });
}

class _LyricTimeSheet extends StatefulWidget {
  const _LyricTimeSheet({
    required this.draft,
    required this.controller,
    required this.index,
    required this.line,
    required this.lower,
    required this.upper,
  });

  final ValueNotifier<Duration> draft;
  final TimedLyricsController controller;
  final int index;
  final String line;
  final Duration lower;
  final Duration upper;

  @override
  State<_LyricTimeSheet> createState() => _LyricTimeSheetState();
}

class _LyricTimeSheetState extends State<_LyricTimeSheet> {
  static const _steps = [10, 100, 500, 1000];
  var _stepMs = 100;

  TimedLyricsController get c => widget.controller;
  int get i => widget.index;

  String _unit(int ms) => ms >= 1000 ? '${ms ~/ 1000}s' : '${ms / 1000}s';

  Duration? get _prev => i > 0 ? c.times[i - 1] : null;
  Duration? get _next => i + 1 < c.times.length ? c.times[i + 1] : null;

  /// 이웃 줄의 시간 사이로 맞춰 임시 값에 넣는다 (가사 칸은 시트가 닫힐 때 바뀐다).
  void _set(Duration to) {
    var d = to;
    final lo = _prev ?? Duration.zero, hi = _next;
    if (d < lo) d = lo;
    if (hi != null && d > hi) d = hi;
    widget.draft.value = d;
  }

  void _setMs(double v) {
    final ms = v.round();
    final lo = widget.lower.inMilliseconds, hi = widget.upper.inMilliseconds;
    // 양 끝 가까이는 이웃 시간에 정확히 붙여 묶이기 쉽게 한다.
    if (ms - lo <= 15) {
      _set(widget.lower);
    } else if (hi - ms <= 15) {
      _set(widget.upper);
    } else {
      _set(Duration(milliseconds: ms ~/ 10 * 10));
    }
  }

  Future<void> _pickUnit(BuildContext tileContext) async {
    final picked = await showAppMenu<int>(
      tileContext,
      items: [
        for (final ms in _steps)
          AppMenuItem(
            value: ms,
            icon: AppIcons.tune,
            label: _unit(ms),
            selected: ms == _stepMs,
          ),
      ],
    );
    if (picked != null && mounted) setState(() => _stepMs = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return ValueListenableBuilder<Duration>(
      valueListenable: widget.draft,
      builder: (context, at, _) {
        final prev = _prev;
        final next = _next;
        final groupedAbove = prev != null && prev == at;
        final groupedBelow = next != null && next == at;

        // 범위 끝 표시: 누르면 그 시간에 붙고, 이미 같아 묶였으면 현재 시간과 같은 색이 된다.
        Widget edge(String title, Duration? t, {required bool end}) {
          final color = t != null && t == at ? p.accent : p.onSurfaceMuted;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t == null ? null : () => _set(t),
            child: Column(
              crossAxisAlignment: end
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.labelSmall?.copyWith(color: p.onSurfaceMuted),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  t == null ? l10n.lyricsTimeNone : lyricTimeLabel(t),
                  style: text.titleSmall?.copyWith(
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          );
        }

        final step = Duration(milliseconds: _stepMs);
        return SafeArea(
          child: SingleChildScrollView(
            padding: appSheetPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSheetTitle(widget.line.isEmpty ? '♪' : widget.line),
                const SizedBox(height: AppSpacing.md),
                GlassSurface(
                  blur: 0,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      StatNumber(lyricTimeLabel(at), size: 44, color: p.accent),
                      const SizedBox(height: AppSpacing.md),
                      AppSlider(
                        value: at.inMilliseconds
                            .clamp(
                              widget.lower.inMilliseconds,
                              widget.upper.inMilliseconds,
                            )
                            .toDouble(),
                        min: widget.lower.inMilliseconds.toDouble(),
                        max: widget.upper.inMilliseconds.toDouble(),
                        semanticLabel: l10n.lyricsTimeNow,
                        onChanged: _setMs,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          edge(l10n.lyricsTimePrev, prev, end: false),
                          edge(l10n.lyricsTimeNext, next, end: true),
                        ],
                      ),
                      if (groupedAbove || groupedBelow) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppIcons.link,
                              size: AppSizes.iconSm,
                              color: p.accent,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Flexible(
                              child: Text(
                                groupedAbove
                                    ? l10n.lyricsTimeGroupedAbove
                                    : l10n.lyricsTimeGroupedBelow,
                                style: text.bodySmall?.copyWith(
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // 한 줄: [−]  단위(누르면 팝업 메뉴)  [+]
                Row(
                  children: [
                    CircleIconButton(
                      icon: AppIcons.remove,
                      tooltip: '−${_unit(_stepMs)}',
                      onPressed: () => _set(at - step),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Builder(
                        builder: (tileContext) => GlassSurface(
                          blur: 0,
                          shape: const StadiumBorder(),
                          onTap: () => _pickUnit(tileContext),
                          child: SizedBox(
                            height: AppSizes.circleButton,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_unit(_stepMs), style: text.titleSmall),
                                const SizedBox(width: AppSpacing.xxs),
                                Icon(
                                  AppIcons.chevronDown,
                                  size: AppSizes.iconSm,
                                  color: p.onSurfaceMuted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    CircleIconButton(
                      icon: AppIcons.add,
                      tooltip: '+${_unit(_stepMs)}',
                      onPressed: () => _set(at + step),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (groupedAbove && c.isGroupedWithAbove(i))
                  MenuRow(
                    icon: AppIcons.restart,
                    label: l10n.lyricsTimeSeparate,
                    onTap: () {
                      c.separate(i);
                      widget.draft.value = c.times[i] ?? at;
                      Navigator.of(context).pop();
                    },
                  ),
                MenuRow(
                  icon: AppIcons.delete,
                  label: l10n.lyricsTimeClearFrom,
                  destructive: true,
                  onTap: () {
                    c.clearFrom(i);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
