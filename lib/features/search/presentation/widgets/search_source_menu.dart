import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/search_source.dart';

/// 검색창 오른쪽 메뉴: 유튜브 / 웹 중 어디서 찾을지 고른다.
/// 검색창에는 아이콘만, 눌러서 열리는 메뉴에는 아이콘 + 이름을 보여 준다.
class SearchSourceMenu extends StatelessWidget {
  const SearchSourceMenu({
    super.key,
    required this.source,
    required this.onChanged,
  });

  final SearchSource source;
  final ValueChanged<SearchSource> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = context.palette;
    String label(SearchSource s) => switch (s) {
      SearchSource.youtube => l10n.sourceYoutube,
      SearchSource.web => l10n.sourceWeb,
    };

    IconData icon(SearchSource s) => switch (s) {
      SearchSource.youtube => Icons.smart_display_rounded,
      SearchSource.web => Icons.public_rounded,
    };

    return PopupMenuButton<SearchSource>(
      tooltip: l10n.searchSourceTooltip,
      initialValue: source,
      onSelected: onChanged,
      color: p.surfaceHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: p.outline),
      ),
      itemBuilder: (_) => [
        for (final s in SearchSource.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Icon(
                  icon(s),
                  size: 20,
                  color: s == source ? p.accent : p.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(label(s)),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon(source), color: p.accent, size: 22)],
          ),
        ),
      ),
    );
  }
}
