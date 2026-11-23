import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';

/// 구분선: 얇은 한 줄(윤곽 색). 목록 · 섹션 사이는 모두 이것으로 나눈다.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.palette.outline);
}
