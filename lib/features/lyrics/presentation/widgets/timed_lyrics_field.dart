import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/timed_lyrics_text.dart';
import '../../../../core/l10n/l10n.dart';
import 'timed_lyrics_controller.dart';

/// 가사 글 한 덩어리를 고치는 칸. 오른쪽은 이어서 복사 · 붙여넣기 할 수 있는 한 개의 입력칸이고,
/// 왼쪽에는 줄 번호에 맞는 싱크 시간을 줄마다 따로 보여 준다 (시간은 고칠 수 없다).
/// 줄 간격을 넓혀 시간과 글이 한 줄씩 맞아 보이게 한다. 긴 줄이 접혀도 시간은 그 줄 맨 위에 선다.
class TimedLyricsField extends StatelessWidget {
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

  List<Duration?> get times => controller.times;

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

  /// 시간 칸을 누르면 그 줄의 싱크를 다듬는 시트를 연다: 시간 조절 · 위/아래 줄과 묶기 · 묶음에서 떼기 · 여기부터 지우기.
  Future<void> _lineActions(BuildContext context, int i, String line) {
    final l10n = context.l10n;
    return showAppSheet<void>(
      context,
      builder: (sheet) => ListenableBuilder(
        listenable: controller,
        builder: (_, _) {
          final at = i < times.length ? times[i] : null;
          if (at == null) return const SizedBox.shrink();
          Widget step(String label, int ms) => PillButton(
            label: label,
            compact: true,
            variant: PillVariant.tonal,
            onPressed: () => controller.adjust(i, Duration(milliseconds: ms)),
          );
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
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      step('−0.5s', -500),
                      step('−0.1s', -100),
                      step('+0.1s', 100),
                      step('+0.5s', 500),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (i > 0 && !controller.isGroupedWithAbove(i))
                    MenuRow(
                      icon: AppIcons.link,
                      label: l10n.lyricsTimeGroupAbove,
                      onTap: () {
                        controller.groupWithAbove(i);
                        Navigator.of(sheet).pop();
                      },
                    ),
                  if (controller.canGroupWithBelow(i))
                    MenuRow(
                      icon: AppIcons.link,
                      label: l10n.lyricsTimeGroupBelow,
                      onTap: () {
                        controller.groupWithBelow(i);
                        Navigator.of(sheet).pop();
                      },
                    ),
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
                        return SizedBox(
                          width: gutter,
                          child: Column(
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
                                    onTap: i < times.length && times[i] != null
                                        ? () =>
                                              _lineActions(context, i, lines[i])
                                        : null,
                                    child: Text(
                                      _label(i),
                                      style: _grouped(i)
                                          ? timeStyle.copyWith(
                                              color: p.accent.withValues(
                                                alpha: .7,
                                              ),
                                            )
                                          : timeStyle,
                                      maxLines: 1,
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
