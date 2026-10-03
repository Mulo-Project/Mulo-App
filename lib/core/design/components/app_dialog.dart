import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';
import 'buttons.dart';

/// 앱 공통 대화상자. 동작 버튼은 항상 맨 아래 한 줄에 같은 너비로 나란히 놓는다.
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
                    icon: Icons.close_rounded,
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
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(child: actions[i]),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
