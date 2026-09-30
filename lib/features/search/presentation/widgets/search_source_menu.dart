import 'package:flutter/material.dart';

import '../../../../core/design/design.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/search_source.dart';

/// 검색창 오른쪽 메뉴: 유튜브 / 웹 중 어디서 찾을지 고른다.
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
          PopupMenuItem(value: s, child: Text(label(s))),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label(source),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: p.accent),
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: p.onSurfaceMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
