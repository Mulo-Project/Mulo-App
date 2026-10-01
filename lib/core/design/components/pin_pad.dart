import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// PIN 입력 판: 입력한 자리 점 + 숫자 키패드.
/// 입력값은 호출한 쪽이 들고 있고, 이 위젯은 모양과 눌림만 맡는다.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.length,
    required this.maxLength,
    required this.onDigit,
    required this.onBackspace,
    required this.backspaceLabel,
    this.leading,
    this.enabled = true,
    this.error = false,
  });

  /// 지금까지 입력한 자릿수.
  final int length;
  final int maxLength;
  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final String backspaceLabel;

  /// 0 왼쪽 칸에 둘 버튼 (생체 인증 등). 없으면 빈 칸.
  final Widget? leading;
  final bool enabled;

  /// true면 점을 오류 색으로 (PIN이 틀렸을 때).
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dotColor = error ? Theme.of(context).colorScheme.error : p.accent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < maxLength; i++)
              AnimatedContainer(
                duration: AppMotion.fast,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs * 2,
                ),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < length ? dotColor : Colors.transparent,
                  border: Border.all(
                    color: i < length ? dotColor : p.onSurfaceMuted,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final d in row)
                  _Key(
                    onTap: enabled ? () => onDigit(d) : null,
                    child: Text('$d'),
                  ),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Key(plain: true, child: leading ?? const SizedBox.shrink()),
            _Key(
              onTap: enabled ? () => onDigit(0) : null,
              child: const Text('0'),
            ),
            _Key(
              plain: true,
              onTap: enabled ? onBackspace : null,
              semanticLabel: backspaceLabel,
              child: const Icon(Icons.backspace_outlined),
            ),
          ],
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.child,
    this.onTap,
    this.plain = false,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// true면 면 없이 아이콘만 (0 옆 칸).
  final bool plain;
  final String? semanticLabel;

  static const double _size = 72;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = Theme.of(context).textTheme.headlineSmall!
        .copyWith(color: p.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Semantics(
        button: onTap != null,
        label: semanticLabel,
        excludeSemantics: semanticLabel != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null && !plain ? .4 : 1,
            child: Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: plain
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      color: p.surface,
                      border: Border.all(color: p.outline),
                    ),
              child: DefaultTextStyle(
                style: style,
                child: IconTheme(
                  data: IconThemeData(color: p.onSurface, size: AppSizes.icon),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
