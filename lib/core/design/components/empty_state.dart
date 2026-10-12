import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 비어 있을 때 · 안내할 때의 가운데 정렬 묶음: (아이콘) · 제목 · 설명 · (버튼).
/// 화면마다 크기 · 간격이 달라지지 않게 빈 화면 안내는 이것으로 그린다.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.action,
  });

  final String title;
  final String? body;
  final IconData? icon;

  /// 아래 버튼 (보통 [PillButton] · [PlainButton]).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSizes.iconEmpty, color: p.accent),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(title, style: text.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              body!,
              style: text.bodyMedium?.copyWith(color: p.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
