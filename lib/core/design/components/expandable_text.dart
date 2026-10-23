import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';

/// 긴 설명 글: [collapsedLines]줄까지 보이고, 그보다 길 때만 "더 보기"가 나온다.
/// 글이나 버튼을 누르면 펼치고 접는다 (영상 · 채널 설명).
class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text, {
    super.key,
    this.collapsedLines = 4,
    this.toggleKey,
  });

  final String text;
  final int collapsedLines;

  /// 더 보기 · 접기 버튼의 키 (테스트용).
  final Key? toggleKey;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: context.palette.onSurfaceMuted);

    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: box.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        final body = AnimatedSize(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          alignment: Alignment.topLeft,
          child: Text(
            widget.text,
            style: style,
            maxLines: _open || !overflows ? null : widget.collapsedLines,
            overflow: _open || !overflows
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
          ),
        );
        if (!overflows) return body;

        void toggle() => setState(() => _open = !_open);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              child: body,
            ),
            Center(
              child: PlainButton(
                key: widget.toggleKey,
                label: _open ? l10n.mediaDetailLess : l10n.mediaDetailMore,
                icon: _open ? AppIcons.chevronUp : AppIcons.chevronDown,
                onPressed: toggle,
              ),
            ),
          ],
        );
      },
    );
  }
}
