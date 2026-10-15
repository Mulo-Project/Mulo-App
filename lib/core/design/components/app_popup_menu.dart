import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 팝업 메뉴 한 줄. [destructive]면 경고 색, [dividerBefore]면 위에 구분선.
class AppMenuItem<T> {
  const AppMenuItem({
    required this.value,
    required this.icon,
    required this.label,
    this.destructive = false,
    this.dividerBefore = false,
    this.iconColor,
    this.selected = false,
  });

  final T value;
  final IconData icon;
  final String label;
  final bool destructive;
  final bool dividerBefore;

  /// 아이콘 색 (색 고르기 같은 메뉴에서 견본으로 쓴다). 없으면 글자 색.
  final Color? iconColor;

  /// 지금 고른 항목이면 오른쪽에 체크 표시.
  final bool selected;
}

/// 눌린 자리(또는 [anchor] 위젯 옆)에 뜨는 팝업 메뉴. 고른 값을 돌려주고, 밖을 누르면 null.
/// 탭 틀(미니 플레이어 · 탭 바) 위에 뜨도록 최상위 내비게이터에서 연다.
///
/// [globalPosition]이 있으면 그 점에서, 없으면 [context]의 위젯 오른쪽 아래에서 연다.
Future<T?> showAppMenu<T>(
  BuildContext context, {
  required List<AppMenuItem<T>> items,
  Offset? globalPosition,
}) {
  final overlay =
      Overlay.of(context, rootOverlay: true).context.findRenderObject()!
          as RenderBox;
  final Rect anchor;
  if (globalPosition != null) {
    anchor = Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0);
  } else {
    final box = context.findRenderObject()! as RenderBox;
    anchor = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlay),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
    );
  }

  final p = context.palette;
  final text = Theme.of(context).textTheme;
  final error = Theme.of(context).colorScheme.error;

  return showMenu<T>(
    context: context,
    useRootNavigator: true,
    position: RelativeRect.fromRect(anchor, Offset.zero & overlay.size),
    color: p.surfaceHigh,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      side: BorderSide(color: p.outline),
    ),
    items: [
      for (final item in items) ...[
        if (item.dividerBefore) const PopupMenuDivider(),
        PopupMenuItem<T>(
          value: item.value,
          child: Row(
            children: [
              Icon(
                item.icon,
                size: AppSizes.iconMd,
                color:
                    item.iconColor ?? (item.destructive ? error : p.onSurface),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  item.label,
                  style: text.bodyLarge?.copyWith(
                    color: item.destructive ? error : p.onSurface,
                  ),
                ),
              ),
              if (item.selected) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(AppIcons.check, size: AppSizes.iconSm, color: p.accent),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
