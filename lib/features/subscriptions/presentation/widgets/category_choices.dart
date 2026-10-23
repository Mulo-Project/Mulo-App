import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/presentation/widgets/video_category.dart';

/// 유튜브 영상 분류를 여러 개 고르는 표: 첫 줄 "모든 분류"(선택을 비운다)가 한 줄을 다 쓰고,
/// 아래는 두 칸씩. 고른 칸은 강조 색 글자 + 체크. 칸 사이는 가는 선으로 나눈다
/// ([selected]가 비어 있으면 모든 분류).
class CategoryChoices extends StatelessWidget {
  const CategoryChoices({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    final names = youtubeCategoryNames;
    final rows = <Widget>[
      _Cell(label: l10n.categoryAll, on: selected.isEmpty, onTap: onClear),
      for (var i = 0; i < names.length; i += 2)
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _Cell(
                  label: categoryLabel(l10n, names[i]),
                  on: selected.contains(names[i]),
                  onTap: () => onToggle(names[i]),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: p.outline),
              Expanded(
                child: i + 1 < names.length
                    ? _Cell(
                        label: categoryLabel(l10n, names[i + 1]),
                        on: selected.contains(names[i + 1]),
                        onTap: () => onToggle(names[i + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ];
    return Material(
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: BorderSide(color: p.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const AppDivider(),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: on ? p.accent : p.onSurface),
              ),
            ),
            if (on)
              Icon(AppIcons.check, size: AppSizes.iconSm, color: p.accent),
          ],
        ),
      ),
    );
  }
}

/// 고른 분류를 한 줄 글로 (없으면 "모든 분류").
String categorySummary(BuildContext context, Set<String> categories) {
  final l10n = context.l10n;
  if (categories.isEmpty) return l10n.categoryAll;
  return [
    for (final name in youtubeCategoryNames)
      if (categories.contains(name)) categoryLabel(l10n, name),
  ].join(', ');
}
