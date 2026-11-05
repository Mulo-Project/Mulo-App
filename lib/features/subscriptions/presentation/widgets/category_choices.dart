import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../search/presentation/widgets/video_category.dart';

/// 유튜브 영상 분류를 여러 개 고르는 칩 묶음: 세 줄로 놓고 옆으로 밀어 본다 (세로 자리를 적게 쓴다).
/// 첫 칩 "모든 분류"는 선택을 비운다 ([selected]가 비어 있으면 모든 분류). 고른 칩은 강조 색 + 체크.
class CategoryChoices extends StatelessWidget {
  const CategoryChoices({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  static const _lines = 3;

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final names = youtubeCategoryNames;
    // 칩을 세 줄에 번갈아 놓는다 (첫 칩은 "모든 분류").
    final chips = <Widget>[
      _chip(l10n.categoryAll, selected.isEmpty, onClear),
      for (final name in names)
        _chip(
          categoryLabel(l10n, name),
          selected.contains(name),
          () => onToggle(name),
        ),
    ];
    final lines = [
      for (var line = 0; line < _lines; line++)
        [for (var i = line; i < chips.length; i += _lines) chips[i]],
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // 화면 가장자리까지 밀려 나가도록 시트 여백만큼 바깥으로 낸다.
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var l = 0; l < lines.length; l++) ...[
            if (l > 0) const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var k = 0; k < lines[l].length; k++) ...[
                  if (k > 0) const SizedBox(width: AppSpacing.xs),
                  lines[l][k],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap) => PillButton(
    label: label,
    icon: on ? AppIcons.check : null,
    compact: true,
    variant: on ? PillVariant.accent : PillVariant.tonal,
    onPressed: onTap,
  );
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
