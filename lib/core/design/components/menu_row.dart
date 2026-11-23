import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 메뉴 시트의 한 줄: 아이콘 + 글자. [destructive]면 경고 색 (삭제 같은 되돌리기 어려운 항목).
class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : p.onSurface;
    // 면 · 테두리 없이 줄만 둔다 (카드 모양을 쓰지 않는다). 누르면 옅게 물든다.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          // 가로 여백 없이 시트 제목과 왼쪽 선을 맞춘다.
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm + AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Icon(icon, size: AppSizes.iconMd, color: color),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
