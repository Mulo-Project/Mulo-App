import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../icons/app_icons.dart';
import '../tokens/app_dimens.dart';

/// 정렬 · 필터 줄에 [AppDropdown]과 나란히 놓는 알약 버튼 (예: "재생목록으로 찾기").
/// 높이 · 면 색 · 글자 크기가 [AppDropdown]과 같아서 한 줄에 놓아도 어긋나지 않는다.
class AppFilterButton extends StatelessWidget {
  const AppFilterButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(
      context,
    ).textTheme.labelLarge!.copyWith(fontSize: 13, color: p.onSurface);
    return Material(
      color: p.surfaceHigh,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: AppFilterButton.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSizes.iconSm, color: p.onSurfaceMuted),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(label, style: text),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// [AppDropdown]과 같은 높이.
  static const double height = 44;
}
