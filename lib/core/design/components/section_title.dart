import 'package:flutter/material.dart';

import '../tokens/app_dimens.dart';

/// 화면 · 시트 안 구역의 제목(titleMedium) 한 줄. 화면에서는 좌우 여백과 아래 틈이 붙고,
/// 시트처럼 바깥이 이미 여백을 가졌으면 [padded]를 끈다.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.padded = true});

  final String title;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final text = Text(title, style: Theme.of(context).textTheme.titleMedium);
    if (!padded) return text;
    return Padding(
      padding: AppSpacing.screen.copyWith(bottom: AppSpacing.xs),
      child: text,
    );
  }
}
