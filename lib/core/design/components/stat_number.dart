import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 큰 숫자 (곡 수, 재생 시간, 퍼센트). 숫자 폭이 고정이라 값이 바뀌어도 흔들리지 않는다.
class StatNumber extends StatelessWidget {
  const StatNumber(this.text, {super.key, this.size = 48, this.color});

  final String text;
  final double size;

  /// 없으면 onSurface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.displayLarge!;
    return Text(
      text,
      maxLines: 1,
      style: base.copyWith(
        fontSize: size,
        height: 1,
        fontWeight: size >= 32 ? FontWeight.w600 : FontWeight.w500,
        letterSpacing: -size * .03,
        color: color ?? context.palette.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
