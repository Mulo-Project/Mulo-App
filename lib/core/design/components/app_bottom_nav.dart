import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// 가운데 대표 탭: 항상 강조 색 원 안에 아이콘을 둔다.
  final bool highlighted;
}

/// 화면 아래에 붙은 단색 탭 바. 선택된 탭은 강조 색 아이콘 + 아래 작은 점.
/// [AppNavItem.highlighted] 탭은 강조 색 원으로 눈에 띄게 그린다.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    final p = context.palette;

    // 화면 아래에 붙은 단색 바 (유리 없음, D-020).
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.outline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.navBarHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    key: ValueKey('nav-${items[i].label}'),
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelected(i),
                    labelStyle: text.labelSmall!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.labelStyle,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.accent : p.onSurfaceMuted;

    if (item.highlighted) {
      return Semantics(
        selected: selected,
        button: true,
        label: item.label,
        child: InkResponse(
          onTap: onTap,
          radius: 36,
          child: ExcludeSemantics(
            child: Center(
              child: AnimatedContainer(
                duration: AppMotion.fast,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.accent : p.accent.withValues(alpha: .18),
                  border: Border.all(color: p.accent, width: 1.5),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected ? p.onAccent : p.accent,
                  size: AppSizes.icon + 2,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: AppSizes.icon,
              ),
              const SizedBox(height: AppSpacing.hair),
              Text(
                item.label,
                style: labelStyle.copyWith(
                  color: color,
                  letterSpacing: 0,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: AppMotion.fast,
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.accent : p.accent.withValues(alpha: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
