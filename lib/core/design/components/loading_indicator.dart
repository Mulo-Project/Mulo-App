import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 앱 전체의 "불러오는 중" 표시: 강조 색의 동그란 진행 표시 하나.
/// 화면 · 목록을 불러올 때는 가운데에 놓는 [LoadingState]를, 버튼 · 줄 안에서는 작은 [size]로 쓴다.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.size = 28, this.color});

  /// 작게 돌아가는 크기 (버튼 · 줄 안).
  const LoadingIndicator.small({super.key, this.color}) : size = 16;

  final double size;

  /// 비우면 강조 색. 버튼 위처럼 바탕에 맞춰야 할 때만 준다.
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: size <= 20 ? 2 : 2.5,
      color: color ?? context.palette.accent,
    ),
  );
}

/// 화면 · 영역을 불러오는 중: 가운데에 [LoadingIndicator] (+ 짧은 안내 문구).
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LoadingIndicator(),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: context.palette.onSurfaceMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    ),
  );
}
