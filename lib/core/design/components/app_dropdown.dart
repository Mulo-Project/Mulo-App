import '../icons/app_icons.dart';

import 'package:flutter/material.dart';

import '../app_theme_tokens.dart';
import '../tokens/app_dimens.dart';

/// 알약 모양 드롭다운 (정렬 기준 고르기 등). 누르면 목록이 펼쳐진다.
/// 문구는 밖에서 받는다 (다국어).
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.tooltip,
    this.icon,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? tooltip;

  /// 선택값 앞에 둘 아이콘 (선택).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme.labelLarge!
        .copyWith(fontSize: 13, color: p.onSurface);

    return PopupMenuButton<T>(
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
                      ? Icon(AppIcons.check, size: 18, color: p.accent)
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
        height: 36,
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.xs,
        ),
        decoration: ShapeDecoration(
          color: p.surfaceHigh,
          shape: StadiumBorder(side: BorderSide(color: p.outline)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: p.onSurfaceMuted),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(labelOf(selected), style: text),
            Icon(AppIcons.dropDown, size: 22, color: p.onSurfaceMuted),
          ],
        ),
      ),
    );
  }
}
