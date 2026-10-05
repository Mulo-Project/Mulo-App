import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';

/// 앱 공통 대화상자. 동작 버튼은 맨 아래 한 줄에 같은 너비로 나란히 놓는다.
/// 글자가 잘릴 만큼 길면 버튼을 세로로 쌓는다.
/// [closeTooltip]을 주면 오른쪽 위에 X 닫기 버튼이 생긴다 (취소 버튼 대신 쓸 때).
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.actions,
    this.body,
    this.content,
    this.closeTooltip,
    this.onClose,
  });

  final String title;
  final String? body;
  final Widget? content;

  /// 아래 한 줄에 놓을 버튼들 (보통 [PillButton]). 한 줄에 맞게 같은 너비로 나뉜다.
  final List<Widget> actions;

  /// X 닫기 버튼의 툴팁. null이면 X를 그리지 않는다.
  final String? closeTooltip;

  /// X를 눌렀을 때. 비우면 아무 값 없이 닫는다.
  final VoidCallback? onClose;

  /// 한 줄에 놓으면 버튼 글자가 `...`로 잘리는가. 그러면 버튼을 세로로 쌓는다.
  bool _stacked(BuildContext context, double width) {
    if (actions.length < 2) return false;
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    final each =
        (width - AppSpacing.sm * (actions.length - 1)) / actions.length;
    for (final a in actions) {
      if (a is! PillButton) continue;
      final padding = (a.compact ? AppSpacing.md : AppSpacing.lg) * 2;
      final icon = a.icon == null ? 0.0 : 18 + AppSpacing.xs;
      final painter = TextPainter(
        text: TextSpan(text: a.label, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > each - padding - icon) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Dialog(
      backgroundColor: p.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: text.titleLarge)),
                if (closeTooltip != null)
                  PlainButton(
                    icon: AppIcons.close,
                    tooltip: closeTooltip,
                    onPressed: onClose ?? () => Navigator.of(context).pop(),
                  ),
              ],
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                body!,
                style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: AppSpacing.md),
              content!,
            ],
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, box) => _stacked(context, box.maxWidth)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.sm),
                          actions[i],
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: actions[i]),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
