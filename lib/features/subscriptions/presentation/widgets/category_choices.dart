import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/presentation/widgets/video_category.dart';

/// 유튜브 영상 분류를 여러 개 고르는 알약 묶음. 첫 알약 "모든 분류"는 선택을 비운다
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
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        PillButton(
          compact: true,
          label: l10n.categoryAll,
          variant: PillVariant.tonal,
          selected: selected.isEmpty,
          onPressed: onClear,
        ),
        for (final name in youtubeCategoryNames)
          PillButton(
            compact: true,
            label: categoryLabel(l10n, name),
            variant: PillVariant.tonal,
            selected: selected.contains(name),
            onPressed: () => onToggle(name),
          ),
      ],
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
