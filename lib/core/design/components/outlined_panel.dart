import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 윤곽선이 있는 옅은 면: 설정 줄 · 표 · 입력 묶음을 한 칸으로 감싸는 기본 모양.
/// (연한 면 색 + 윤곽선 + 작은 둥근 모서리. 화면마다 같은 모양을 직접 만들지 않는다.)
class OutlinedPanel extends StatelessWidget {
  const OutlinedPanel({super.key, required this.child, this.radius});

  final Widget child;

  /// 모서리 둥글기. 정하지 않으면 작은 반경([AppRadii.sm]).
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: p.surfaceHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius ?? AppRadii.sm),
          side: BorderSide(color: p.outline),
        ),
      ),
      child: child,
    );
  }
}
