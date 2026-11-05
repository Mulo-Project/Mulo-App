import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 알약 모양 드롭다운 (정렬 기준 고르기 등). 누르면 목록이 펼쳐진다.
/// 문구는 밖에서 받는다 (다국어).
///
/// [onToggleDirection]을 주면 알약 오른쪽에 구분선 · 방향 화살표가 붙어 한 덩어리가 된다
/// (기준 고르기 + 오름 · 내림차순 바꾸기를 따로 떨어진 아이콘 없이 한 알약으로).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.tooltip,
    this.icon,
    this.ascending,
    this.onToggleDirection,
    this.directionTooltip,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? tooltip;

  /// 선택값 앞에 둘 아이콘 (선택).
  final IconData? icon;

  /// 정렬 방향 (true 오름차순). [onToggleDirection]과 함께 준다.
  final bool? ascending;
  final VoidCallback? onToggleDirection;

  /// 방향 화살표의 설명 (지금 방향을 말한다. 예: "오름차순").
  final String? directionTooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelLarge!
        .copyWith(fontSize: 13, color: p.onSurface);
    final toggle = onToggleDirection;

    final label = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSizes.iconXs, color: p.onSurfaceMuted),
          const SizedBox(width: AppSpacing.xxs),
        ],
        Text(labelOf(selected), style: text),
        Icon(AppIcons.dropDown, size: AppSizes.iconSm, color: p.onSurfaceMuted),
      ],
    );

    final menu = PopupMenuButton<T>(
      tooltip: tooltip,
      initialValue: selected,
      onSelected: onChanged,
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: p.outline),
      ),
      itemBuilder: (_) => [
        for (final v in values)
          PopupMenuItem<T>(
            value: v,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: v == selected
                      ? Icon(
                          AppIcons.check,
                          size: AppSizes.iconSm,
                          color: p.accent,
                        )
                      : null,
                ),
                Flexible(
                  child: Text(
                    labelOf(v),
                    style: text,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        alignment: Alignment.center,
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: toggle == null ? AppSpacing.xs : 0,
        ),
        child: label,
      ),
    );

    // 테두리 없이 옅은 면 하나로 단순하게 (검색칸과 같은 높이 · 같은 면).
    return Container(
      height: 44,
      decoration: ShapeDecoration(
        color: p.surfaceHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          menu,
          if (toggle != null) ...[
            Tooltip(
              message: directionTooltip ?? '',
              child: InkWell(
                onTap: toggle,
                customBorder: const StadiumBorder(),
                child: SizedBox(
                  width: 40,
                  height: 44,
                  child: Icon(
                    (ascending ?? true) ? AppIcons.arrowUp : AppIcons.arrowDown,
                    size: AppSizes.iconSm,
                    color: p.onSurfaceMuted,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
