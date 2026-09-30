import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 화면 바탕: 테마 배경색 단색 (다크 / 라이트).
///
/// 배경은 유리 · 빛 효과 없이 둔다 (D-015). 유리는 떠 있는 바 · 버튼 · 강조 카드에만.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.palette.background,
    child: child ?? const SizedBox.expand(),
  );
}
