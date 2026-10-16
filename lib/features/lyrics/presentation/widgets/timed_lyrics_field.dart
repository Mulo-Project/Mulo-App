import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../domain/entities/timed_lyrics_text.dart';

/// 가사 글 한 덩어리를 고치는 칸. 오른쪽은 이어서 복사 · 붙여넣기 할 수 있는 한 개의 입력칸이고,
/// 왼쪽에는 줄 번호에 맞는 싱크 시간을 줄마다 따로 보여 준다 (시간은 고칠 수 없다).
/// 줄 간격을 넓혀 시간과 글이 한 줄씩 맞아 보이게 한다. 긴 줄이 접혀도 시간은 그 줄 맨 위에 선다.
class TimedLyricsField extends StatelessWidget {
  const TimedLyricsField({
    super.key,
    required this.controller,
    required this.times,
    this.hint,
  });

  final TextEditingController controller;

  /// 줄 번호별 시간. 비어 있으면 시간 칸 없이 글만 보인다.
  final List<Duration> times;
  final String? hint;

  static const _gutter = 68.0;
  static const _pad = AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = Theme.of(context).textTheme.bodyMedium!;
    final style = base.copyWith(height: 2.0);
    final timeStyle = style.copyWith(color: p.onSurfaceMuted);
    final scaler = MediaQuery.textScalerOf(context);

    // 상자 · 테두리 없이 가사 보기처럼 조용하게 보인다.
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = times.isEmpty ? 0.0 : _gutter;
        final textWidth = box.maxWidth - gutter - _pad;
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (times.isNotEmpty)
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
                              child: Text(
                                i < times.length
                                    ? lyricTimeLabel(times[i])
                                    : '',
                                style: timeStyle,
                                maxLines: 1,
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
